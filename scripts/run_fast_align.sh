#!/bin/bash

set -ex

bpe=""
if (( $# == 1 )); then
  if [ "$1" != "bpe" ]; then
    echo "Use BPE as the first argument if you want to run fastalign using BPE tokenization"
    exit 1
  fi
  bpe=".bpe"
  echo "Using BPE"
fi


mkdir -p fastalign
cd fastalign

for ln_pair in "roen" "deen" "enfr"; do
  train_src="../train/${ln_pair}.lc.plustest.src${bpe}"
  train_tgt="../train/${ln_pair}.lc.plustest.tgt${bpe}"
  ../scripts/fast_align.sh ${train_src} ${train_tgt} ${ln_pair}${bpe}

  if (( $# == 1 )); then
    # For the bpe case we additionally have to convert the subword alignments to word alignments
    # Additionally we only care about the test set (fast align does not align empty source or target segments, which makes matching the lines more difficult)
    hypo="${ln_pair}${bpe}.word.talp"
    hypo_reverse="${ln_pair}${bpe}.word.reverse.talp"
    test_src="../test/${ln_pair}.lc.src.bpe"
    test_tgt="../test/${ln_pair}.lc.tgt.bpe"
    reference_lines=`cat ${test_src} | wc -l`
    tail -n ${reference_lines} ${ln_pair}${bpe}.talp > ${ln_pair}${bpe}.test.talp
    tail -n ${reference_lines} ${ln_pair}${bpe}.reverse.talp > ${ln_pair}${bpe}.test.reverse.talp

    ../scripts/sentencepiece_to_word_alignments.py ${test_src} ${test_tgt} < ${ln_pair}${bpe}.test.talp > ${hypo}
    ../scripts/sentencepiece_to_word_alignments.py ${test_tgt} ${test_src} < ${ln_pair}${bpe}.test.reverse.talp > ${hypo_reverse}
    ../scripts/combine.sh ${hypo} ${hypo_reverse} ../test/${ln_pair}.talp > ${ln_pair}${bpe}-results.txt
  else
    ../scripts/combine.sh ${ln_pair}.talp ${ln_pair}.reverse.talp ../test/${ln_pair}.talp > ${ln_pair}-results.txt
  fi
done

cd -

