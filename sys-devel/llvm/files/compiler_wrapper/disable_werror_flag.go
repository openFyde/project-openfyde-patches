// Copyright 2019 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path"
	"regexp"
	"strconv"
	"strings"
	"unicode"
)

const (
	numWErrorEstimate = 30
	// '0' means 'disable error limiting'.
	unlimitedErrorsFlag = "-ferror-limit=0"
)

func getForceDisableWerrorDir(env env, cfg *config) string {
	return path.Join(getCompilerArtifactsDir(env), "toolchain/fatal_clang_warnings")
}

type forceDisableWerrorConfig struct {
	// If reportToStdout is true, we'll write -Werror reports to stdout. Otherwise, they'll be
	// written to reportDir. If reportDir is empty, it will be determined via
	// `getForceDisableWerrorDir`.
	//
	// Neither of these have specified values if `enabled == false`.
	reportDir      string
	reportToStdout bool

	// If true, `-Werror` reporting should be used.
	enabled bool
}

func processForceDisableWerrorFlag(env env, cfg *config, builder *commandBuilder) (forceDisableWerrorConfig, error) {
	// TODO: It's unclear that this branch is still useful. If not, it should be removed.
	if cfg.isAndroidWrapper && cfg.useLlvmNext {
		return forceDisableWerrorConfig{
			reportToStdout: true,
			enabled:        true,
		}, nil
	}

	// CrOS supports two modes for enabling this flag:
	// 1 (preferred). A CFLAG that specifies the directory to write reports to. e.g.,
	//   `-D_CROSTC_FORCE_DISABLE_WERROR=/path/to/directory`. This flag will be removed from the
	//   command before the compiler is invoked. If multiple of these are passed, the last one
	//   wins, but all are removed from the build command.
	// 2 (dispreferred, but supported). An environment variable, FORCE_DISABLE_WERROR, set to
	//   any nonempty value. In this case, the wrapper will write to either
	//   ${CROS_ARTIFACTS_TMP_DIR}/toolchain/fatal_clang_warnings, or to
	//   /tmp/toolchain/fatal_clang_warnings.
	//
	// Two modes are supported because some ebuilds filter the env, while others will filter
	// CFLAGS. Vanishingly few (none?) filter both, though.
	cflagPrefix := "-D_CROSTC_FORCE_DISABLE_WERROR="

	if cfg.isAndroidWrapper {
		// Android supports one mode for this flag: -D_ANDROID_FORCE_DISABLE_WERROR=/dev/stdout. At
		// present, writing to any other file or directory is almost certainly a bug, since most Android
		// builds happen on RBE, so auxiliary files won't get sent back to the user. In the future, the
		// same flow as CrOS might be possible.
		cflagPrefix = "-D_ANDROID_FORCE_DISABLE_WERROR="
	}

	forceDisableArg := ""
	sawArg := false
	builder.transformArgs(func(arg builderArg) string {
		value := arg.value
		if !strings.HasPrefix(value, cflagPrefix) {
			return value
		}
		forceDisableArg = value[len(cflagPrefix):]
		sawArg = true
		return ""
	})

	// CrOS only wants this functionality to apply to clang, though flags should also be removed
	// for GCC.
	// Android is assumed to only use Clang.
	if !cfg.isAndroidWrapper && builder.target.compilerType != clangType {
		return forceDisableWerrorConfig{enabled: false}, nil
	}

	if sawArg {
		if cfg.isAndroidWrapper {
			// As mentioned above, only /dev/stdout is supported here, given the room for foot-guns with
			// RBE. The hope is that RBE can be modified to treat this as a true 'reportDir' in the future.
			if forceDisableArg != "/dev/stdout" {
				err := fmt.Errorf("invalid value for FORCE_DISABLE_WERROR: %q; only /dev/stdout is valid", forceDisableArg)
				return forceDisableWerrorConfig{}, err
			}
			return forceDisableWerrorConfig{
				reportToStdout: true,
				enabled:        true,
			}, nil
		}

		return forceDisableWerrorConfig{
			reportDir: forceDisableArg,
			// Skip this when in src_configure: some build systems ignore CFLAGS
			// modifications after configure, so this flag must be specified before
			// src_configure, but we only want the flag to apply to actual builds.
			enabled: !isInConfigureStage(env),
		}, nil
	}

	// Env enablement is only supported on CrOS; Android's build system filters env at multiple
	// points, so it's not an ergonomic way to interface with this feature.
	if !cfg.isAndroidWrapper {
		envValue, _ := env.getenv("FORCE_DISABLE_WERROR")
		return forceDisableWerrorConfig{enabled: envValue != ""}, nil
	}

	return forceDisableWerrorConfig{enabled: false}, nil
}

func disableWerrorFlags(originalArgs, extraFlags []string) []string {
	allExtraFlags := append([]string{}, extraFlags...)
	newArgs := make([]string, 0, len(originalArgs)+numWErrorEstimate)
	for _, flag := range originalArgs {
		if strings.HasPrefix(flag, "-Werror=") {
			allExtraFlags = append(allExtraFlags, strings.Replace(flag, "-Werror", "-Wno-error", 1))
		}
		if !strings.Contains(flag, "-warnings-as-errors") {
			newArgs = append(newArgs, flag)
		}
	}
	return append(newArgs, allExtraFlags...)
}

func isLikelyAConfTest(env env, cfg *config, cmd *command) bool {
	// Android doesn't do mid-build `configure`s, so we don't need to worry about this there.
	if cfg.isAndroidWrapper {
		return false
	}

	cwd := env.getwd()
	// Ignore anything that's likely to be a cmake configuration step. These put the compiler
	// into a TryCompile dir.
	if strings.Contains(cwd, "CMakeFiles/CMakeScratch/TryCompile-") {
		return true
	}

	wasLastArgOutput := false
	for _, a := range cmd.Args {
		// The kernel, for example, will do configure tests with /dev/null as a source file.
		if a == "/dev/null" || strings.HasPrefix(a, "conftest.c") {
			return true
		}

		// b/417950454: scons conftests run during src_compile at times, but consistently use
		// `-o ${some_dir}/.sconf.temp/conftest_${hash}_${num}.o`.
		if wasLastArgOutput {
			if strings.HasSuffix(a, ".o") && strings.Contains(a, "/.sconf.temp/conftest_") {
				return true
			}

			// b/424460547: perf (and other kernel tools, seemingly) have a special method of running
			// configure checks during src_compile. Detect that here. Generally speaking, these builds are
			// run in the `build/feature` subdirectory, and have `-o test-*` on their commandline.
			if strings.HasPrefix(path.Base(a), "test-") && strings.HasSuffix(cwd, "tools/build/feature") && strings.Contains(cwd, "/dev-util/perf-") {
				return true
			}
			wasLastArgOutput = false
		} else {
			wasLastArgOutput = a == "-o"
		}
	}
	return false
}

func getWnoErrorFlags(stdout, stderr []byte) []string {
	needWnoError := false
	extraFlags := []string{}
	for _, submatches := range regexp.MustCompile(`error:.* \[(-W[^\]]+)\]`).FindAllSubmatch(stderr, -1) {
		bracketedMatch := submatches[1]

		// Some warnings are promoted to errors by -Werror. These contain `-Werror` in the
		// brackets specifying the warning name. A broad, follow-up `-Wno-error` should
		// disable those.
		//
		// _Others_ are implicitly already errors, and will not be disabled by `-Wno-error`.
		// These do not have `-Wno-error` in their brackets. These need to explicitly have
		// `-Wno-error=${warning_name}`. See b/325463152 for an example.
		if bytes.HasPrefix(bracketedMatch, []byte("-Werror,")) || bytes.HasSuffix(bracketedMatch, []byte(",-Werror")) {
			needWnoError = true
		} else {
			// In this case, the entire bracketed match is the warning flag. Trim the
			// first two chars off to account for the `-W` matched in the regex.
			warningName := string(bracketedMatch[2:])
			extraFlags = append(extraFlags, "-Wno-error="+warningName)
		}
	}
	needWnoError = needWnoError || bytes.Contains(stdout, []byte("warnings-as-errors")) || bytes.Contains(stdout, []byte("clang-diagnostic-"))

	if len(extraFlags) == 0 && !needWnoError {
		return nil
	}
	return append(extraFlags, "-Wno-error")
}

type wnoErrorResult struct {
	exitCode               int
	stdout                 *bytes.Buffer
	stderr                 *bytes.Buffer
	commitRusage           func(int) error
	redirectStderrToStdout bool
}

func isOutputLimitedByErrorLimit(s string) bool {
	return strings.Contains(s, "too many errors emitted, stopping now")
}

func buildSuppressingWerrorImpl(env env, cfg *config, originalCmd *command, werrorConfig forceDisableWerrorConfig) (result *wnoErrorResult, err error) {
	originalStdoutBuffer := &bytes.Buffer{}
	originalStderrBuffer := &bytes.Buffer{}

	getStdin, err := prebufferStdinIfNeeded(env, originalCmd)
	if err != nil {
		return nil, wrapErrorwithSourceLocf(err, "prebuffering stdin: %v", err)
	}

	var originalExitCode int
	commitOriginalRusage, err := maybeCaptureRusage(env, originalCmd, func(willLogRusage bool) error {
		originalExitCode, err = wrapSubprocessErrorWithSourceLoc(originalCmd,
			env.run(originalCmd, getStdin(), originalStdoutBuffer, originalStderrBuffer))
		return err
	})
	if err != nil {
		return nil, err
	}

	originalBuildResult := &wnoErrorResult{
		exitCode:               originalExitCode,
		stdout:                 originalStdoutBuffer,
		stderr:                 originalStderrBuffer,
		commitRusage:           commitOriginalRusage,
		redirectStderrToStdout: false,
	}

	// The only way we can do anything useful is if it looks like the failure
	// was -Werror-related.
	retryWithExtraFlags := []string{}
	if originalExitCode != 0 && !isLikelyAConfTest(env, cfg, originalCmd) {
		retryWithExtraFlags = getWnoErrorFlags(originalStdoutBuffer.Bytes(), originalStderrBuffer.Bytes())
	}
	if len(retryWithExtraFlags) == 0 {
		return originalBuildResult, nil
	}

	commandToLog := originalCmd
	stdoutAndStderrToLog := strings.TrimSpace(originalStderrBuffer.String() + "\n" + originalStdoutBuffer.String())
	// We're now at the point where we want to rebuild with -Wno-error to see if things get
	// fixed. `getWnoErrorFlags` parses stdout and stderr for `-Werror`s to disable, and Clang
	// may hide `-Werror`s from that due to `-ferror-limit`. Consider rerunning with a very high
	// -ferror-limit value
	if isOutputLimitedByErrorLimit(stdoutAndStderrToLog) {
		// If the original output is limited:
		//   - we should generate -Werror suppressions from the output of a command that
		//     isn't
		//   - we should also generate the -Werror _report_ based on the unlimited command,
		//     since that's more likely to be helpful for debugging after the fact.
		stdout := &bytes.Buffer{}
		stderr := &bytes.Buffer{}
		// Append to a new slice, since we don't want to mutate the underlying buffer of
		// `originalCmd`.
		newArgs := append(append([]string{}, originalCmd.Args...), unlimitedErrorsFlag)
		ferrorLimitCmd := &command{
			Path:       originalCmd.Path,
			Args:       newArgs,
			EnvUpdates: originalCmd.EnvUpdates,
		}
		_, err := wrapSubprocessErrorWithSourceLoc(originalCmd,
			env.run(ferrorLimitCmd, getStdin(), stdout, stderr))
		if err != nil {
			return nil, err
		}

		commandToLog = ferrorLimitCmd
		stdoutAndStderrToLog = strings.TrimSpace(stderr.String() + "\n" + stdout.String())
		// This isn't checked for nonemptiness, since it's assumed that the new output will
		// be a strict superset of the old.
		retryWithExtraFlags = getWnoErrorFlags(stdout.Bytes(), stderr.Bytes())
	}

	retryStdoutBuffer := &bytes.Buffer{}
	retryStderrBuffer := &bytes.Buffer{}
	retryCommand := &command{
		Path:       originalCmd.Path,
		Args:       disableWerrorFlags(originalCmd.Args, retryWithExtraFlags),
		EnvUpdates: originalCmd.EnvUpdates,
	}

	var retryExitCode int
	commitRetryRusage, err := maybeCaptureRusage(env, retryCommand, func(willLogRusage bool) error {
		retryExitCode, err = wrapSubprocessErrorWithSourceLoc(retryCommand,
			env.run(retryCommand, getStdin(), retryStdoutBuffer, retryStderrBuffer))
		return err
	})
	if err != nil {
		return nil, err
	}

	// If -Wno-error fixed us, pretend that we never ran without -Wno-error. Otherwise, pretend
	// that we never ran the second invocation.
	if retryExitCode != 0 {
		return originalBuildResult, nil
	}

	// If we fail this, it's reasonable for that to fail the build. This is all meant for FYI-like
	// builders in the first place.
	if err := writeWerrorReport(env, cfg, commandToLog, stdoutAndStderrToLog, werrorConfig); err != nil {
		return nil, fmt.Errorf("writing -Werror report: %v", err)
	}

	return &wnoErrorResult{
		exitCode:     retryExitCode,
		stdout:       retryStdoutBuffer,
		stderr:       retryStderrBuffer,
		commitRusage: commitRetryRusage,
		// b/448874348#comment2: rarely, we see interleaving between stdout and stderr. If
		// we're logging our -Werror report to stdout, it's best to not write anything to
		// stderr in order to avoid this. In practice, we only write to stdout on Android
		// builds, and Android builds happen through Ninja, which merges both streams into a
		// single one anyway.
		redirectStderrToStdout: werrorConfig.reportToStdout,
	}, nil
}

func buildSuppressingWerror(env env, cfg *config, originalCmd *command, werrorConfig forceDisableWerrorConfig) (exitCode int, err error) {
	result, err := buildSuppressingWerrorImpl(env, cfg, originalCmd, werrorConfig)
	if err != nil {
		return 0, err
	}

	if err := result.commitRusage(result.exitCode); err != nil {
		return 0, fmt.Errorf("commiting rusage: %v", err)
	}
	result.stdout.WriteTo(env.stdout())

	if result.redirectStderrToStdout {
		result.stderr.WriteTo(env.stdout())
	} else {
		result.stderr.WriteTo(env.stderr())
	}
	return result.exitCode, nil
}

// bytes.TrimSpace(), but on a buffer, and only the right-hand side of it.
func trimRightSpacesInPlace(buf *bytes.Buffer) {
	trimmed := bytes.TrimRightFunc(buf.Bytes(), unicode.IsSpace)
	buf.Truncate(len(trimmed))
}

func writeWerrorReport(env env, cfg *config, originalCmd *command, stdoutAndStderr string, werrorConfig forceDisableWerrorConfig) error {
	// Ignore the error here; we can't do anything about it. The result is always valid (though
	// perhaps incomplete) even if this returns an error.
	parentProcesses, _ := collectAllParentProcesses()
	jsonData := warningsJSONData{
		Cwd:             env.getwd(),
		Command:         append([]string{originalCmd.Path}, originalCmd.Args...),
		Stdout:          stdoutAndStderr,
		ParentProcesses: parentProcesses,
	}

	// Write warning report to stdout for Android.  On Android,
	// double-build can be requested on remote builds as well, where there
	// is no canonical place to write the warnings report.
	if werrorConfig.reportToStdout {
		// Write this all to a buffer, since we have to write the JSON to a buffer of some
		// sort anyway, to postprocess it.
		writeBuf := &bytes.Buffer{}
		writeBuf.WriteString("<LLVM_NEXT_ERROR_REPORT>")
		if err := json.NewEncoder(writeBuf).Encode(jsonData); err != nil {
			return wrapErrorwithSourceLocf(err, "error in json.Marshal")
		}
		// Go's JSON package writes whitespace after the JSON object, and we can't turn that
		// behavior off.
		trimRightSpacesInPlace(writeBuf)
		writeBuf.WriteString("</LLVM_NEXT_ERROR_REPORT>\n")
		env.stdout().Write(writeBuf.Bytes())
		return nil
	}

	// Buildbots use a nonzero umask, which isn't quite what we want: these directories should
	// be world-readable and world-writable.
	oldMask := env.umask(0)
	defer env.umask(oldMask)

	reportDir := werrorConfig.reportDir
	if reportDir == "" {
		reportDir = getForceDisableWerrorDir(env, cfg)
	}

	// Allow root and regular users to write to this without issue.
	if err := os.MkdirAll(reportDir, 0777); err != nil {
		return wrapErrorwithSourceLocf(err, "error creating warnings directory %s", reportDir)
	}

	// Have some tag to show that files aren't fully written. It would be sad if
	// an interrupted build (or out of disk space, or similar) caused tools to
	// have to be overly-defensive.
	const incompleteSuffix = ".incomplete"

	// Coming up with a consistent name for this is difficult (compiler command's
	// SHA can clash in the case of identically named files in different
	// directories, or similar); let's use a random one.
	tmpFile, err := os.CreateTemp(reportDir, "warnings_report*.json"+incompleteSuffix)
	if err != nil {
		return wrapErrorwithSourceLocf(err, "error creating warnings file")
	}

	if err := tmpFile.Chmod(0666); err != nil {
		return wrapErrorwithSourceLocf(err, "error chmoding the file to be world-readable/writeable")
	}

	enc := json.NewEncoder(tmpFile)
	if err := enc.Encode(jsonData); err != nil {
		_ = tmpFile.Close()
		return wrapErrorwithSourceLocf(err, "error writing warnings data")
	}

	if err := tmpFile.Close(); err != nil {
		return wrapErrorwithSourceLocf(err, "error closing warnings file")
	}

	if err := os.Rename(tmpFile.Name(), tmpFile.Name()[:len(tmpFile.Name())-len(incompleteSuffix)]); err != nil {
		return wrapErrorwithSourceLocf(err, "error removing incomplete suffix from warnings file")
	}
	return nil
}

func parseParentPidFromPidStat(pidStatContents string) (parentPid int, ok bool) {
	// The parent's pid is the fourth field of /proc/[pid]/stat. Sadly, the second field can
	// have spaces in it. It ends at the last ')' in the contents of /proc/[pid]/stat.
	lastParen := strings.LastIndex(pidStatContents, ")")
	if lastParen == -1 {
		return 0, false
	}

	thirdFieldAndBeyond := strings.TrimSpace(pidStatContents[lastParen+1:])
	fields := strings.Fields(thirdFieldAndBeyond)
	if len(fields) < 2 {
		return 0, false
	}

	fourthField := fields[1]
	parentPid, err := strconv.Atoi(fourthField)
	if err != nil {
		return 0, false
	}
	return parentPid, true
}

func collectProcessData(pid int) (args, env []string, parentPid int, err error) {
	procDir := fmt.Sprintf("/proc/%d", pid)

	readFile := func(fileName string) (string, error) {
		s, err := os.ReadFile(path.Join(procDir, fileName))
		if err != nil {
			return "", fmt.Errorf("reading %s: %v", fileName, err)
		}
		return string(s), nil
	}

	statStr, err := readFile("stat")
	if err != nil {
		return nil, nil, 0, err
	}

	parentPid, ok := parseParentPidFromPidStat(statStr)
	if !ok {
		return nil, nil, 0, fmt.Errorf("no parseable parent PID found in %q", statStr)
	}

	argsStr, err := readFile("cmdline")
	if err != nil {
		return nil, nil, 0, err
	}
	args = strings.Split(argsStr, "\x00")

	envStr, err := readFile("environ")
	if err != nil {
		return nil, nil, 0, err
	}
	env = strings.Split(envStr, "\x00")
	return args, env, parentPid, nil
}

// The returned []processData is valid even if this returns an error. The error is just the first we
// encountered when trying to collect parent process data.
func collectAllParentProcesses() ([]processData, error) {
	results := []processData{}
	for parent := os.Getppid(); parent != 1; {
		args, env, p, err := collectProcessData(parent)
		if err != nil {
			return results, fmt.Errorf("inspecting parent %d: %v", parent, err)
		}
		results = append(results, processData{Args: args, Env: env})
		parent = p
	}
	return results, nil
}

type processData struct {
	Args []string `json:"invocation"`
	Env  []string `json:"env"`
}

// Struct used to write JSON. Fields have to be uppercase for the json encoder to read them.
type warningsJSONData struct {
	Cwd             string        `json:"cwd"`
	Command         []string      `json:"command"`
	Stdout          string        `json:"stdout"`
	ParentProcesses []processData `json:"parent_process_data"`
}
