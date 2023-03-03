#!/bin/bash
# set -x
parts=$1

if [ "$parts" == "" ]; then
    parts="1 2 3";
fi


scriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# echo "$scriptdir"

file=$2
echo $file
function myecho {
    if [ $2 -ne 0 ]; then
        if ! [ -z $file ]; then
            echo "$1" >> $scriptdir/$file
        else
            echo "$1"
        fi
    fi
}

ID_BASE="unit"
ID_PROJTEST="${ID_BASE}/class:Tests"

function grade_bin {
    LB=$2
    HB=$3
    BINS=$4
    UNIT=$5
    d=$6
    local score=0
    for ((number=BINS; number>0; number--)); do

        if [ $BINS -eq 1 ]; then
            range=$HB
        else
            range=$(echo "scale=scale($LB);$LB+($HB-$LB)/($BINS-1)*($number-1)" | bc)
        fi

		ID_TEST="${ID_PROJTEST}/method:$1_LE_$range()"
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}" "http://$REPORT_HOST/started"

        re='^[0-9]+\.?[0-9]*$'
        if  [[ $d =~ $re ]] ; then


            cond=$(echo "$d <= $range" | bc 2>/dev/null)
            if [ $cond -eq 1 ]; then
                myecho "Project.$1_LE_$range: PASSED" 1
                score=$(($score+1))
				RESULT=successful
				CAUSE=""
            else
                myecho "Project.$1_LE_$range: FAILED, you have $d $UNIT which is greater than $range $UNIT" 1
				RESULT=failed
				CAUSE="You have $d $UNIT which is greater than $range $UNIT"
            fi
        else
            myecho "Project.$1_LE_$range: $d" 1
			RESULT=failed
			CAUSE="$d"
        fi

		if [[ "$RESULT" == "successful" ]]; then CAUSE=""; fi
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}&cause=$CAUSE" "http://$REPORT_HOST/finished/$RESULT"
	done;
    return $score;
}

# 1: test name
# 2: test command
# 3: previous test status, 0 success 1 fail
# 4: previous test name
# 5: do echo or not (!0, 0)
# 6: timeout limit (e.g., 90s, 3m)
function run_or_timeout {
	ID_TEST="${ID_PROJTEST}/method:$1()"
	[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}" "http://$REPORT_HOST/started"

  if [ $3 -ne 0 ] ; then
      myecho "Project.$1: FAILED You must pass the $4 before running other tests" $5
      failmsg="FAILED You must pass the $4 before running other tests"
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}&cause=$failmsg" "http://$REPORT_HOST/finished/failed"
      return 1
  fi
  result="$(timeout $6 $2)"
  if [ $? -eq 124 ] ; then
      myecho "Project.$1: FAILED TEST TIMEOUT" $5
      failmsg="FAILED TEST TIMEOUT"
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}&cause=$failmsg" "http://$REPORT_HOST/finished/failed"
    return 1
  fi
  failed=$(echo "$result" | grep "FAILED")
  passed=$(echo "$result" | grep "PASSED")
  if [ -n "$failed" ] || [ -z "$passed" ] ; then
      myecho "Project.$1: FAILED" $5
      failmsg="FAILED"
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}&cause=$failmsg" "http://$REPORT_HOST/finished/failed"
      return 1
  fi
  myecho "Project.$1: PASSED" $5
	[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}&cause=" "http://$REPORT_HOST/finished/successful"
  return 0
}

# Signal start of testing
[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_BASE}" "http://$REPORT_HOST/started"
[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_PROJTEST}&description=Project Tests (optional)" "http://$REPORT_HOST/started"

score_sec1=0
score_sec2=0
score_sec3=0

for part in $parts
do
    cd $scriptdir
    if [ $part == "1" ]; then
        # Part 1: Software optimization (sort)
        cd part1
        make all -j 2 -s

		ID_TEST="${ID_PROJTEST}/method:Part1_sort_test()"
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}" "http://$REPORT_HOST/started"

        if [ -f ./sort_test.vmh ] && [ -f ./sort_bench.vmh ]; then
            out_test=`timeout 5s rv_sim sort_test --auto`
            pass=`echo "$out_test" | grep -Eo "PASSED"`
            fail=`echo "$out_test" | grep -Eo "FAILED"`
            if [ -n "$fail" ]; then
                myecho "Project.Part1_sort_test: FAILED" 1
                instrs="FAILED, sort_test failed"
				RESULT=failed
            elif ! [[ -z "$pass" ]] ; then
                myecho "Project.Part1_sort_test: PASSED" 1
                instrs=`rv_sim sort_bench --auto | grep -E "Executed Instrs " | sed  's/||.*//g' | grep -Eo "([0-9]+)"`
				RESULT=successful
            else
                myecho "Project.Part1_sort_test: FAILED, neither passed nor failed printed" 1
                instrs="FAILED, neither passed nor failed printed"
				RESULT=failed
            fi
        else
            myecho "Project.sort_test: FAILED, compilation error" 1
            instrs="FAILED, compilation error"
			RESULT=failed
        fi

		CAUSE=$instrs
		if [[ "$RESULT" == "successful" ]]; then CAUSE=""; fi
		[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_TEST}&cause=$CAUSE" "http://$REPORT_HOST/finished/$RESULT"

        grade_bin "Part1_sort_sw_optimization" 325000 400000 2 instructions "$instrs"
        score_sec1=$(($score_sec1+$?))
        grade_bin "Part1_sort_sw_optimization" 250000 250000 1 instructions "$instrs"
        score_sec1=$(($score_sec1+$?))
        grade_bin "Part1_sort_sw_optimization" 210000 210000 1 instructions "$instrs"
        score_sec1=$(($score_sec1+$?))
        echo "Part 1 Score = $score_sec1"
    elif [ $part == "2" ]; then
        # Part 2: ProcessorIPC
        cd part2
        run_or_timeout "Part2_IPC-fullasmtests" "./test.py --didit f" 0 none 1 120s
        run_or_timeout "Part2_IPC-pipetests" "./test.py --didit p" $? fullasmtests 1 15s
        run_or_timeout "Part2_IPC-sort_base" "./test.py --didit s1" $? pipetests 0 7m
        succeed=$?
        cpi=$failmsg
        caches=1
        if [ $succeed -eq 0 ]; then
            periodlimit=550
            numinstrs=445555
            period=`echo "$result" | grep -Eo "has clock period = ([0-9]+\.?[0-9]*) ps" | grep -Eo "([0-9]+\.?[0-9]*)"`
            cond=`echo "$period <= $periodlimit" | bc 2> /dev/null`
            if [ $cond -eq 1 ]; then
                cycles=`echo "$result" | grep -Eo "Total Cycles = ([0-9]+)" | grep -Eo "([0-9]+)"`
                if [ $cycles -lt 400000 ]; then
                    cpi="FAILED, Sort aborted early"
                fi
                cpi=$(echo "scale=2;$cycles/$numinstrs" | bc)
            else
                cpi="FAILED, Your processor has clock period ($period ps) exceeding $periodlimit ps"
            fi
            caches=`echo "$result" | grep "Instruction and data caches present: YES"`
            caches=$?
            # caches = 0 if present, 1 if not present
        fi
        if [ $caches -eq 1 ]; then
            grade_bin "Part2_IPC-sort_base-no_caches" 1.5 1.5 1 CPI "$cpi"
            # Add TWO points if they pass this
            score_sec2=$(($score_sec2+$?+$?))
        else
            grade_bin "Part2_IPC-sort_base-with_caches" 1.5 2.5 3 CPI "$cpi"
            score_inc=$?
            # Score is 4, 5, 6 for the 3 bins so add 3 extra if they passed anything
            if [ $score_inc -gt 0 ]; then score_sec2=$(($score_sec2+$score_inc+3)); fi
        fi
        echo "Part 2 Score = $score_sec2"
    elif [ $part == "3" ]; then
        # Part 3: ProcessorRuntime
        cd part3
        run_or_timeout "Part3_Runtime-fullasmtests" "./test.py --didit f" 0 none 1 120s
        run_or_timeout "Part3_Runtime-pipetests" "./test.py --didit p" $? fullasmtests 1 15s
        run_or_timeout "Part3_Runtime-sort_test" "./test.py --didit --quick s2" $? pipetests 1 60s
        run_or_timeout "Part3_Runtime-sort_bench" "./test.py --didit s3" $? sort_test 0 7m
        succeed=$?
        runtime="$failmsg"
        if [ $succeed -eq 0 ]; then
            cycles=`echo "$result" | grep -Eo "Total Cycles = ([0-9]+)" | grep -Eo "([0-9]+)"`
            if [ $cycles -lt 50000 ]; then
                runtime="FAILED, Sort aborted early"
            else
                runtime=`echo "$result" | grep -Eo "Runtime = ([0-9]+)" | grep -Eo "([0-9]+)"`
            fi
            caches=`echo "$result" | grep "Instruction and data caches present: YES"`
            caches=$?
            # caches = 0 if present, 1 if not present
            if [ $caches -eq 1 ]; then
                runtime="FAILED, You must use data and instruction caches"
            fi
        fi
        grade_bin "Part3_Runtime-sort_bench" 135000 180000 4 ns "$runtime"
        score_sec3=$(($score_sec3+$?))
        grade_bin "Part3_Runtime-sort_bench" 95000 125000 4 ns "$runtime"
        score_sec3=$(($score_sec3+$?))
        grade_bin "Part3_Runtime-sort_bench" 85000 90000 2 ns "$runtime"
        score_sec3=$(($score_sec3+$?))
        echo "Part 3 Score = $score_sec3"
    fi
done

# Signal end of Tests
[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_PROJTEST}" "http://$REPORT_HOST/finished/successful"
[[ $REPORT_HOST ]] && wget -q --post-data="id=${ID_BASE}" "http://$REPORT_HOST/finished/successful" || true 


# exit success here otherwise makefile will complain
exit 0;
