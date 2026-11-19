import WordCounterBadges from "../../components/word-counter-badges";

<template>
  <WordCounterBadges
    @badges={{@outletArgs.post.word_counter_badges}}
    @user={{@outletArgs.user}}
  />
</template>
