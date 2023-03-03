#!/bin/bash

LABNUM=Lab5
COMP_FAIL_MSG=" - COMPILE ERROR"

ID_BASE="unit"
ID_MAND="${ID_BASE}/class:Mandatory Tests"
ID_OPT="${ID_BASE}/class:Optional Tests"

function grade_test {
    # Arguments:
    #   $1: Didit class ID
    #   $2: Name of test / Executable to run
	#   (Unused) $3: 

    ID_TEST="$1/method:$2()"

    if [ ! -f ./buildDir/$2 ]; then
	RESULT=aborted
        CAUSE="$LABNUM.$2: FAILED${COMP_FAIL_MSG}"
    else 
        temp_out=$(timeout 30s ./buildDir/$2)
        sim_exit_code=${PIPESTATUS[0]}
        if [ $sim_exit_code -eq 124 ] ; then
	    RESULT=aborted
            CAUSE="$LABNUM.$2: FAILED - SIM TIMEOUT"
        elif [ $sim_exit_code -ne 0 ] ; then
	    RESULT=aborted
            CAUSE="$LABNUM.$2: FAILED - SIM ERROR"
        elif echo "$temp_out" | grep -q FAILED; then
	    RESULT=failed
            CAUSE="$LABNUM.$2: $(echo "$temp_out" | grep -e FAILED)"
        elif echo "$temp_out" | grep -q PASSED; then
	    RESULT=successful
            CAUSE="$LABNUM.$2: $(echo "$temp_out" | grep -e PASSED)"
			TEST_PASSED=1 # for grade_test_with_synth
        else
	    RESULT=aborted
            CAUSE="$LABNUM.$2: FAILED - UNKNOWN PROBLEM, report to staff"
        fi
    fi

    echo "$CAUSE"
    # Don't send a CAUSE to Didit if we passed the test
    if [[ "$RESULT" == "successful" ]]; then CAUSE=""; fi
}

function grade_test_with_synth {
    # Arguments:
    #   $1: Didit class ID
    #   $2: ms filename to feed into synth
	#   $3: module name to search for in the ms file
    #   $4: Name of test / Executable to run
	#   $5: <Less Than> Requirement

	# run the functionality check first
	TEST_PASSED=0
	grade_test "$1" "$4"
	if [ $TEST_PASSED -ne 1 ]; then
		ID_TEST="$1/method:$4_LE_$5()"

		RESULT=aborted
		CAUSE="$LABNUM.$4_LE_$5: FAILED - Not run, you must PASS $4 first"
		echo "$CAUSE"
		return
	fi

	# only if passed $4
    ID_TEST="$1/method:$4_LE_$5()"

	synth_msg=$(timeout 100s synth $2 $3 -l multisize --synthdir synthDir_$4 > $2_$3_synth_out 2>&1)
	delay=$(cat $2_$3_synth_out | grep -E "Critical-path delay:" | grep -Eo "([0-9]+\.?[0-9]*)");
	if [[ $delay != "" ]]; then
		echo "your circuit $3 delay is $delay";
		test=$(echo "$delay < $5" | bc)
		if [ $test -ne 0 ]; then
			RESULT=successful
			CAUSE="$LABNUM.$4_LE_$5: PASSED"
		else
			result=failed
			CAUSE="$LABNUM.$4_LE_$5: FAILED - your delay ($delay) is greater than $4"
		fi
	else
		echo "Your circuit $3 delay could not be found";
		echo "Synth message: ";
		cat $2_$3_synth_out
	    RESULT=failed
		CAUSE="$LABNUM.$4_LE_$5: failed - could not find the delay... "
	fi

    echo "$CAUSE"
    # Don't send a CAUSE to Didit if we passed the test
    if [[ "$RESULT" == "successful" ]]; then CAUSE=""; fi
}

# Signal start of testing

# Mandatory Tests

grade_test "${ID_MAND}" "MultiplyByAddingTest"
grade_test "${ID_MAND}" "FoldedMultiplierTest"
grade_test_with_synth "${ID_MAND}" "PipelineMath.ms" "PipelineMath" "PipelineMathTest" 500
grade_test_with_synth "${ID_MAND}" "SortingNetworks.ms" "BitonicSorter8" "BitonicSorterTest" 250

ID_TEST="${ID_MAND}/method:Discussion()"
if [[ `wc -c < ./discussion_questions.txt` -gt 100 ]]; then
    echo "Lab5.Discussion: PASSED"
else
    CAUSE="Lab5.Discussion: FAILED less than 100 chars in discussion_questions.txt - put your discussion answers into this file"
    echo $CAUSE
fi


# Optional Tests

grade_test_with_synth "${ID_OPT}" "Multipliers.ms" "FastFoldedMultiplier#(32)" "FastFoldedMultiplierTest" 280


# Signal end of testing
## 'true' prevents this script from returning bad status when REPORT_HOST is not set
