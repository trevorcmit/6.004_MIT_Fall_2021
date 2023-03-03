#!/bin/bash

LABNUM=Lab6
COMP_FAIL_MSG=" - COMPILE ERROR"

ID_BASE="unit"
ID_MAND="${ID_BASE}/class:Mandatory Tests"
ID_OPT="${ID_BASE}/class:Optional Tests"

function run_or_timeout {
	# Arguments:
	#   $1: Didit class ID
	#   $2: Name of test
	#   $3: Executable to run
	#   $4: Force Fail

	ID_TEST="$1/method:$2()"

	if [[ "$4" -ne "0" ]] ; then
		CAUSE="Lab6.$2: FAILED You must pass the microtests before running other tests"
		echo $CAUSE
		return 1
	fi

	result="$(timeout 45s $3)"
	exitcode=$?
	if [ $exitcode -eq 124 ] ; then
		CAUSE="Lab6.$2: FAILED TEST TIMEOUT"
		echo $CAUSE
		return 1
	fi

	if [ $exitcode -eq 127 ] ; then
		CAUSE="Lab6.$2: FAILED ${COMP_FAIL_MSG}"
		echo $CAUSE
		return 1
	fi

	failed=$(echo "$result" | grep "FAILED")
	passed=$(echo "$result" | grep "PASSED")
	lastline=$(echo "$result" | tail -n1)
	if [ -n "$failed" ] || [ -z "$passed" ] ; then
		CAUSE="Lab6.$2: FAILED | $lastline"
		echo $CAUSE
		return 1
	fi

	echo "Lab6.$2: PASSED"
	CAUSE=""
}

# Signal start of testing

# Mandatory Tests

run_or_timeout "${ID_MAND}" "Decode" "./DecodeTB" 0
run_or_timeout "${ID_MAND}" "Execute" "./ExecuteTB" 0
run_or_timeout "${ID_MAND}" "Microtests" "./test.py a --didit" 0
microtests_result=$?
run_or_timeout "${ID_MAND}" "Fullasmtests" "./test.py f --didit" $microtests_result
run_or_timeout "${ID_MAND}" "Quicksort" "./test.py q --didit"  $microtests_result

ID_TEST="${ID_MAND}/method:Discussion()"
if [[ `wc -c < ./discussion_questions.txt || echo 0` -gt 100 ]]; then
	echo "Lab6.Discussion: PASSED"
else
    CAUSE="Lab6.Discussion: FAILED less than 100 chars in discussion_questions.txt - put your discussion answers into this file"
    echo $CAUSE
fi

# Signal end of Mandatory Tests

# Signal end of testing
## 'true' prevents this script from returning bad status when REPORT_HOST is not set
