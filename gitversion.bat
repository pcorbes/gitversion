:: Git version script for Windows to extract and update source files
:: Copyright (c) 2023 Philippe Corbes released under the MIT license

@echo off
@pushd .
SETlocal enabledelayedexpansion
set exit_code=0

IF %PROCESSOR_ARCHITECTURE% == x86 (
	IF DEFINED PROCESSOR_ARCHITEW6432 (
		set git_bin="%ProgramFiles(x86)%\git\bin"
	) ELSE (
		set git_bin="%ProgramFiles%\git\bin"
	)
) ELSE IF %PROCESSOR_ARCHITECTURE% == AMD64 (
	:: set git_bin="%ProgramFiles(x86)%\git\bin"
	set git_bin="%ProgramFiles%\git\bin"
) ELSE (
	set git_bin="%ProgramFiles%\git\bin"
)
:: Remove quotes
SET git_bin=!git_bin:"=!
:: " quote to make Sublime Text happy...

:: verify if the sed command is available
sed -V 1> nul
IF %ERRORLEVEL% NEQ 0 (
	@echo ERROR: No sed command found. Please install it from https://unxutils.sourceforge.net/ 
	SET exit_code=1
	GOTO FINITO
)

:: Preprocessing parameters

:: Preprocessing parameter 1
IF [%1] EQU [] (
	SET root_dir=.
) ELSE (
	SET root_dir=%1
)

@echo -------------------------------------------------------------------------------------------

:: verify that .git exists within given directory
IF EXIST %root_dir% (
	CD /d %root_dir%
	"!git_bin!\git.exe" describe --tags 1>nul
	IF %ERRORLEVEL% NEQ 0 (
		@echo ERROR: No git repository in given directory!
		SET exit_code=1
		GOTO FINITO
	)
) ELSE (
	@echo ERROR: Missing Git repo directory!
	SET exit_code=1
	GOTO USAGE
)

:: To get latest abbriviated hash from git
:: git log -n 1 --pretty="format:%h"
:: To get current tag
:: git describe --tags
:: git describe --tags --long | sed "s,v\([0-9]*\).*,\1,"
:: git describe --tags --long --dirty | sed "s,\([a-zA-Z0-9_+-]*\.[0-9]*\.[0-9]*\)-[0-9]*-g.*,\1,"

::!current_tag! 
FOR /F "tokens=1 delims=" %%A in ('"!git_bin!\git.exe" describe --tags --long --dirty') do SET current_tag=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| sed "s,\([a-zA-Z0-9_+-]*\.[0-9]*\.[0-9]*\)-[0-9]*-g.*,\1,"') do SET tag_only=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| sed "s,[a-zA-Z_+-]*\([0-9]*\).*,\1,"') do SET major_version=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| sed "s,[a-zA-Z0-9_+-]*\.\([0-9]*\).*,\1,"') do SET minor_version=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| sed "s,[a-zA-Z0-9_+-]*\.[0-9]*\.\([0-9]*\).*,\1,"') do SET revision=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| sed "s,[a-zA-Z0-9_+-]*\.[0-9]*\.[0-9]*-\([0-9]*\).*,\1,"') do SET commits_since_tag=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| sed "s,[a-zA-Z0-9_+-]*\.[0-9]*\.[0-9]*-[0-9]*-g\([0-9a-f]*\).*,\1,"') do SET git_hash=%%A
SET git_hash=!git_hash: =!

IF %commits_since_tag% == 0 (
	set git_commits=
) ELSE (
	set git_commits=+%commits_since_tag%
)

::!git_tag_complete_with_hash!
FOR /F "tokens=1 delims=" %%A in ('"!git_bin!\git.exe" describe !tag_only! --tags --long') do SET git_tag_complete_with_hash=%%A
FOR /F "tokens=1 delims=" %%A in ('echo !git_tag_complete_with_hash! ^| sed "s,[a-zA-Z0-9_+-]*\.[0-9]*\.[0-9]*-[0-9]*-g\(.*\),\1,"') do SET git_tag_hash=%%A
SET git_tag_hash=!git_tag_hash: =!

::!dirty_tag!
FOR /F "tokens=1 delims=" %%A in ('echo !current_tag! ^| tr -d " \r\n" ^| sed "s,.*\(-dirty\).*,\1,"') do SET git_dirty=%%A
IF [x%git_dirty%] NEQ [x-dirty] (
	SET git_dirty=
)

@echo * Tags replaced in input file:
@echo   [MAJOR_VERSION]:     '!major_version!'
@echo   [MINOR_VERSION]:     '!minor_version!'
@echo   [REVISION]:          '!revision!'
@echo   [GIT_TAG_ONLY]:      '!tag_only!'
@echo   [GIT_TAG_HASH]:      '!git_tag_hash!'
@echo   [COMMITS_SINCE_TAG]: '!commits_since_tag!'
@echo   [GIT_CURRENT_TAG]:   '!current_tag!'
@echo   [GIT_CURRENT_HASH]:  '!git_hash!'
@echo   [GIT_COMMITS_FLAG]:  '!git_commits!'
@echo   [GIT_DIRTY_FLAG]:    '!git_dirty!'

:: skip the file transformation if no more parameters
IF [x%2x] == [xx] IF [x%3x] == [xx] GOTO FINITO

@echo - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

:: Preprocessing parameter 2
IF [%2] NEQ [] (
	:: verify that input file exists
	IF NOT EXIST %2 (
		@echo ERROR: Input file does not exist
		SET exit_code=1
		GOTO FINITO
	)
)

:: Preprocessing parameter 3
IF [%3] NEQ [] (
	:: Check that input != output
	IF [%3] EQU [%2] (
		@echo ERROR: Input and ouput filename is equal.
		SET exit_code=1
		GOTO FINITO
	)
) ELSE (
	@echo ERROR: Missing the outputfile parameter.
	SET exit_code=1
	GOTO USAGE
)

:: get the old tag if exist
IF EXIST %3.tag (
	for /f %%G in (%3.tag) do (SET old_tag=%%G)
)

IF EXIST %3 IF EXIST %3.tag IF [x!old_tag!x] == [x!current_tag!x] GOTO UPDATED

@echo * Updating git version
@echo -   Using git repository : !root_dir!
@echo -   using input file     : %2
@echo -   output to file       : %3

:: if output file exists, just warn about it
IF EXIST %3 (
	@echo WARNING: output file exists. Will overwrite it...
)

:: Replace parameters in file using sed
sed ^
	-e "s,\[MAJOR_VERSION\],!major_version!,g" ^
	-e "s,\[MINOR_VERSION\],!minor_version!,g" ^
	-e "s,\[REVISION\],!revision!,g" ^
	-e "s,\[GIT_TAG_ONLY\],!tag_only!,g" ^
	-e "s,\[GIT_TAG_HASH\],!git_tag_hash!,g" ^
	-e "s,\[COMMITS_SINCE_TAG\],!commits_since_tag!,g" ^
	-e "s,\[GIT_CURRENT_TAG\],!current_tag!,g" ^
	-e "s,\[GIT_CURRENT_HASH\],!git_hash!,g" ^
	-e "s,\[GIT_COMMITS_FLAG\],!git_commits!,g" ^
	-e "s,\[GIT_DIRTY_FLAG\],!git_dirty!,g" ^
	<%2 >%3

:: record the actual curent tag
echo !current_tag! > %3.tag
GOTO FINITO

:UPDATED
@echo * No need to update the output file: %3
GOTO FINITO

:USAGE
@echo -------------------------------------------------------------------------------------------
@echo  usage: gitversion.bat [folder_with_git_repo [inputfile outputfile]]
@echo  example: gitversion.bat c:\my_git_repo version_input.h version.h
@echo  -
@echo  Important note: This expects tags to be in format: Anything else won't work. 
@echo  [optional text including lowercase, uppercase, _, + and -]1.0.123 where 1 is major, 
@echo  0 is minor and 123 is revision. The sed command needs to be available in the PATH
@echo  -
@echo  Tags replaced in input file:
@echo     [MAJOR_VERSION]     - the major version number
@echo     [MINOR_VERSION]     - the minor version number
@echo     [REVISION]          - the revision number
@echo     [GIT_TAG_ONLY]      - only the last git tag
@echo     [GIT_TAG_HASH]      - git hash for the last git tag
@echo     [COMMITS_SINCE_TAG] - number of commits since last tag
@echo     [GIT_CURRENT_TAG]   - git current tag
@echo     [GIT_CURRENT_HASH]  - the current git tag hash
@echo                           (will be same as GIT_TAG_HASH if the current tag is checked out)
@echo     [GIT_COMMITS_FLAG]  - Empty or +number_of_commits_since_last_tag
@echo     [GIT_DIRTY_FLAG]    - Empty or '-dirty' if not synchronized

:FINITO
@echo -------------------------------------------------------------------------------------------
EndLocal&SET exit_code=!exit_code!
popd
exit /B !exit_code!
