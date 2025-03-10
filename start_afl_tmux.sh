#!/bin/bash 

set -x

INPUT_DIR="/pwd/inputs-without-bad"
OUTPUT_DIR="/pwd/outputs-new"
FUZZ_BINARY="/root/iptables/afl-install/sbin/iptables-restore"
TMUX_SESSION_NAME="afl_fuzzing"
NUM_INSTANCES=4

tmux new-session -d -s $TMUX_SESSION_NAME

tmux new-window -t $TMUX_SESSION_NAME:1 -n "master"
tmux send-keys -t $TMUX_SESSION_NAME:1 "afl-fuzz -i $INPUT_DIR -o $OUTPUT_DIR -M master -- $FUZZ_BINARY @@" C-m

for i in $(seq 1 $NUM_INSTANCES); do
	INSTANCE_NAME="slave-$i"
	tmux new-window -t $TMUX_SESSION_NAME:$i -n "$INSTANCE_NAME"
	tmux send-keys -t $TMUX_SESSION_NAME:$i "afl-fuzz -i $INPUT_DIR -o $OUTPUT_DIR -M $INSTANCE_NAME -- $FUZZ_BINARY @@" C-m 
done

tmux select-window -t $TMUX_SESSION_NAME:1 
tmux attach-session -t $TMUX_SESSION_NAME
