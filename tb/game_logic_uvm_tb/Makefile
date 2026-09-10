.PHONY: comp run conduct bpm score full full_case speed_ram verdi coverage clean
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
TEST ?= conduct_fsm_test
WAVE ?= $(TEST).fsdb
REPEAT ?= 3
VCS = vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps
VCS += -debug_access+all -kdb -lca
# RTL의 line/condition/branch/FSM/toggle code coverage를 수집한다.
CM = line+cond+branch+fsm+tgl
CM_HIER = tb_ai/cm_hier.cfg
VCS += -cm $(CM) -cm_hier $(CM_HIER)

comp:
	cd $(ROOT) && $(VCS) -f tb_ai/files.f -o simv -cm_dir coverage.vdb

run: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_LOW +SEQ_REPEAT=$(REPEAT) +FSDB_FILE=$(TEST).fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name $(TEST)

conduct: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=conduct_fsm_test +SEQ_REPEAT=$(REPEAT) +FSDB_FILE=conduct_fsm_test.fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name conduct
bpm: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=bpm_calc_test +SEQ_REPEAT=$(REPEAT) +FSDB_FILE=bpm_calc_test.fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name bpm
score: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=score_test +SEQ_REPEAT=$(REPEAT) +FSDB_FILE=score_test.fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name score
full: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=full_game_scenario_test +SEQ_REPEAT=$(REPEAT) +FSDB_FILE=full_game_scenario_test.fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name full
full_case: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=full_case_coverage_test +SEQ_REPEAT=1 +FSDB_FILE=full_case_coverage_test.fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name full_case
speed_ram: comp
	cd $(ROOT) && ./simv +UVM_TESTNAME=speed_ram_debug_test +FSDB_FILE=speed_ram_debug_test.fsdb -cm $(CM) -cm_dir coverage.vdb -cm_name speed_ram

verdi:
	cd $(ROOT) && verdi -dbdir simv.daidir -ssf $(WAVE) &

coverage:
	# coverage.vdb 전체를 Verdi Coverage 창으로 연다.
	cd $(ROOT) && verdi -cov -covdir coverage.vdb &

clean:
	cd $(ROOT) && rm -rf simv simv.daidir simv.vdb csrc ucli.key vc_hdrs.h *.fsdb coverage.vdb
