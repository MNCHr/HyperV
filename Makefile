#BMv2_DIR=/home/netarchlab/behavioral-model/targets/simple_switch
BMv2_DIR=/home/hr-dev/behavioral-model/targets/simple_switch
MAIN_FILE=hyperv.p4
ALL_FILE=hyperv_all.p4
HR_FILE=hyperv_hr.p4

COMMIT_REASON=?"defaut commit"
LOG="--log-console"
INTF1="-i 1@p4p1" 
INTF2="-i 2@p4p2"

## p4c-bm2-ss compiler#####################################
compile_main:
	@mkdir -p build
	@p4c-bm2-ss src/${MAIN_FILE} --std p4-14 -o build/hyperv.json
compile_all:
	@mkdir -p build
	@p4c-bm2-ss src/${ALL_FILE} --std p4-14 -o build/hyperv_all.json

compile_hr:
	@mkdir -p build
	@p4c-bm2-ss src/${HR_FILE} --std p4-14 -o build/hyperv_hr.json

## "2" means p4c-bmv2 compiler  ##################################### 
compile_main2:
	@mkdir -p build
	@@p4c-bmv2 src/${MAIN_FILE} --json build/hyperv2.json
compile_all2:
	@mkdir -p build
	@@p4c-bmv2 src/${ALL_FILE} --json build/hyperv2_all.json

compile_hr2:
	@mkdir -p build
	@@p4c-bmv2 src/${HR_FILE} --json build/hyperv2_hr.json

#######################################

clean:
	@rm -rf build

git:
	@git add -A
	@git commit -a -m $COMMIT_REASON
	@git push -u origin master

run: 
	@cp build/hyperv.json $(BMv2_DIR)
	@cd $(BMv2_DIR)&&sudo bash simple_switch hyperv.json $(INTF1) $(INTF2) $(LOG)

run2: 
	@cp build/hyperv2.json $(BMv2_DIR)
	@cd $(BMv2_DIR)&&sudo bash simple_switch hyperv2.json $(INTF1) $(INTF2) $(LOG)

run2_hr: 
	@cp build/hyperv2_hr.json $(BMv2_DIR)
	@cd $(BMv2_DIR)&&sudo bash simple_switch hyperv2_hr.json $(INTF1) $(INTF2) $(LOG)
