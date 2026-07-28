#!/bin/bash

# Add RVM repository
add-apt-repository -y ppa:brightbox/ruby-ng

# Update package lists
apt-get update

# Install Ruby 2.3 and related packages
apt-get install -y ruby2.3 ruby2.3-dev bundler
