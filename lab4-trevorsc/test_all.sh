#!/bin/bash

LABNUM=Lab4
COMP_FAIL_MSG=" - COMPILE ERROR or ILLEGAL OPERATOR USED"

ID_BASE="unit"
ID_MAND="${ID_BASE}/class:Mandatory Tests"
ID_OPT="${ID_BASE}/class:Optional Tests"

function grade_test {
    # Arguments:
    #   $1: Didit class ID
    #   $2: Name of test
    #   $3: Executable to run

    ID_TEST="$1/method:$2()"

    if [ ! -f ./$3 ]; then
	RESULT=aborted
        CAUSE="$LABNUM.$2: FAILED${COMP_FAIL_MSG}"
    else
        temp_out=$(timeout 15s ./$3)
        sim_exit_code=${PIPESTATUS[0]}
        if [ $sim_exit_code -eq 124 ] ; then
	    RESULT=aborted
            CAUSE="$LABNUM.$2: FAILED - SIM TIMEOUT"
        elif [ $sim_exit_code -ne 0 ] ; then
	    RESULT=aborted
            CAUSE="$LABNUM.$2: FAILED - SIM ERROR"
        elif echo "$temp_out" | grep -q FAILED; then
	    RESULT=failed
            CAUSE="$(echo "$temp_out" | grep -e FAILED)"
        elif echo "$temp_out" | grep -q PASSED; then
	    RESULT=successful
            CAUSE="$(echo "$temp_out" | grep -e PASSED)"
        else
	    RESULT=aborted
            CAUSE="$LABNUM.$2: FAILED - UNKNOWN PROBLEM, report to staff"
        fi
    fi

    echo "$CAUSE"
    # Don't send a CAUSE to Didit if we passed the test
    if [[ "$RESULT" == "successful" ]]; then CAUSE=""; fi
}

function grade_bin {
    # Generates a sequence of evenly spaced thresholds between two bounds and
    #   then compares the input value to those thresholds.  Reports a PASS for
    #   all thresholds where the input is less than or equal to the threshold
    #   and a FAIL for all others.
    #
    # Arguments:
    #   $1: Didit class ID
    #   $2: Test base name
    #   $3: Lower bound
    #   $4: Upper bound
    #   $5: Number of thresholds (bins) to create
    #   $6: Text label, the units for the input value (e.g., ns, cycles)
    #   $7: Input value (This should be EITHER:
    #         a) an integer/real number followed by optional (ignored) text OR
    #         b) "FAILED" followed by a reason why the number is not available 

    NAME=$2
    LB=$3
    HB=$4
    BINS=$5
    UNIT=$6
    d=$7

    local score=0
    for ((number=BINS; number>0; number--)); do
        if [ $BINS -eq 1 ]; then
            range=$HB
        else
            range=$(echo "scale=scale($LB);$LB+($HB-$LB)/($BINS-1)*($number-1)" | bc)
        fi
	ID_TEST="$1/method:${NAME}_LE_$range()"

        re='^[0-9]+\.?[0-9]*$'
        if  [[ $d =~ $re ]] ; then
            cond=$(echo "$d <= $range" | bc 2>/dev/null)
            if [ $cond -eq 1 ]; then
		RESULT=successful
                CAUSE="$LABNUM.${NAME}_LE_$range: PASSED"
                score=$(($score+1))
            else
		RESULT=failed
		CAUSE="$LABNUM.${NAME}_LE_$range: FAILED, you have $d $UNIT which is greater than $range $UNIT"
            fi
        else
	    RESULT=aborted
            CAUSE="$LABNUM.${NAME}_LE_$range: $d"
        fi
	
	echo "$CAUSE"
	# Don't send a CAUSE to Didit if we passed the test
	if [[ "$RESULT" == "successful" ]]; then CAUSE=""; fi
	
    done;
    return $score;
}

# Signal start of testing

# Mandatory Tests
grade_test "${ID_MAND}" "Right_Shifter" "Tb_sr32"
grade_test "${ID_MAND}" "SLL_Shifter" "Tb_sll32"
grade_test "${ID_MAND}" "FULL_Shifter" "Tb_sft32" 
grade_test "${ID_MAND}" "LTu_Comparator" "Tb_ltu32"
grade_test "${ID_MAND}" "LT_Comparator" "Tb_lt32"
grade_test "${ID_MAND}" "RCA_Adder" "Tb_rca32"
grade_test "${ID_MAND}" "AdderSubtractor" "Tb_addSub32"
grade_test "${ID_MAND}" "ALU" "Tb_alu"

ID_TEST="${ID_MAND}/method:Discussion()"
if [[ `wc -c < ./discussion_questions.txt` -gt 100 ]]; then
    echo "Lab4.Discussion: PASSED"
else
    CAUSE="Lab4.Discussion: FAILED less than 100 chars in discussion_questions.txt - put your discussion answers into this file"
    echo $CAUSE
fi



# Optional Tests

if [[ ! -f ./Tb_fastAdd32 ]]; then
    DELAY="FAILED${COMP_FAIL_MSG}"
else
    temp_out=$(timeout 15s ./Tb_fastAdd32)
    sim_exit_code=${PIPESTATUS[0]}
    if [[ $sim_exit_code -eq 124 ]] ; then
        DELAY="FAILED - SIM TIMEOUT"
    elif [ $sim_exit_code -ne 0 ] ; then
        DELAY="FAILED - SIM ERROR"
    elif echo "$temp_out" | grep -q FAILED; then
        DELAY="$(echo "$temp_out" | grep -e FAILED | sed 's/Lab4.FASTADD32: / /')"
    elif echo "$temp_out" | grep -q PASSED; then
	DELAY=$(timeout 70s synth ALU.ms "fastAdd#(32)" -l multisize | grep -E "Critical-path delay:" | grep -Eo "([0-9]+\.?[0-9]*)")
        if [[ $DELAY == "" ]]; then
	    DELAY="FAILED - SYNTHESIS FAILED OR TIMED OUT"
	else
	    echo "Your fast adder delay is $DELAY ps."
	fi
    else
        DELAY="FAILED - UNKNOWN PROBLEM, report to staff"
    fi
fi

grade_bin "${ID_OPT}" "Fast_Adder_Delay" 200 400 5 "ps" "$DELAY"


# Signal end of testing
## 'true' prevents this script from returning bad status when REPORT_HOST is not set
