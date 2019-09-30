FROM ruby:2.6-slim

COPY ./Gemfile ./Gemfile

RUN bundle install
