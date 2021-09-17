# gha_config

This gem will process a templated file and output a GitHub Action workflow file specific to Flipp workflows. The idea is that you can maintain a small, lean config file without a lot of repetition and copy/pasting, and process it to export a "real" workflow file for GitHub to use.

## Installation

You will need Ruby 2.3 or greater to run this (you can install this via Homebrew if you don't have it). Make sure you have the latest version of Rubygems as well.

Install using `gem install gha_config`.

## Usage

Create a file called `.github/workflow-src/CI.yml` in the base directory of your app. You can think of this file as a regular GitHub Action workflow file, except for two differences:

1. Certain "global / always needed" steps and settings do not need to be added, as they will be auto-added after processing.
2. The file supports special *template* keys which can be replaced later on.

Run the command with `gha_config` - it will output the file into `.github/workflows/CI.yml`.

### Template keys

Template keys are very similar to [YAML anchors](http://blogs.perl.org/users/tinita/2019/05/reusing-data-with-yaml-anchors-aliases-and-merge-keys.html). Unfortunately GitHub does not support anchors, and in addition anchors have a weakness in that you cannot use them to extend arrays/lists.

Template keys all begin and end with underscores: `_`. You define template keys in a special `_defaults_` section in your config, and you can use them elsewhere.

Here's an example of a templated GitHub Action workflow file.

```yaml
on:
  pull_request:
  push:
    branches:
    - master
    - develop

_defaults_:
  _container_:
    image: ghcr.io/wishabi/ci-build-environment:ruby-3.0-buster-node
    credentials:
        username: ${{ github.repository_owner }}
        password: ${{ secrets.GHCR_TOKEN }}
  _cache_:
    - name: Bundle cache
      uses: actions/cache@v2
      with:
        path: vendor/bundle
        key: rails-${{ hashFiles('Gemfile.lock') }}
        restore-keys: rails-
  _teardown_:
    - name: Cleanup
    - run: docker cleanup
  _setup_:
    - _cache_
    - name: Bundle install
      run: bundle install --jobs=4

jobs:
  build:
    container: _container_
    steps:
      - _setup_
      - name: Print build
        run: ls dist/
      - _teardown_
```

The output of this file will look like this (you can see that it auto-creates the checkout and "Flipp global" steps):

```yaml
name: CI

on:
  pull_request:
  push:
    branches:
    - master
    - develop

env:
  HOME: /home/circleci
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  AWS_REGION: ${{ secrets.AWS_REGION }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

jobs:

  build:
    runs-on: [ubuntu, runner-fleet]
    container:
      image: dockerhub-username:docker-image-tag:ruby-3.0
      credentials:
        username: "${{ github.repository_owner }}"
        password: "${{ secrets.GHCR_TOKEN }}"
    steps:
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Flipp global
      uses: wishabi/my-cool-action
    - name: Bundle cache
      uses: actions/cache@v2
      with:
        path: vendor/bundle
        key: rails-${{ hashFiles('Gemfile.lock') }}
        restore-keys: rails-
    - name: Bundle install
      run: bundle install --jobs=4
    - name: Print build
      run: ls dist/
    - name: Cleanup
      run: docker cleanup
```

Templates get expanded into their contents whenever they are used. Templates can also include templates (as you can see that the `_setup_` template includes the `_cache_` template). Finally, if a template is used inside a list of steps, the expansion will continue the list rather than nest it.

If you're using Ruby, you can add this gem to your app Gemfile. Otherwise, you can install it locally. Either way, you can re-run it whenever your "source workflow" changes.

### Variables

You can define simple variables in a separate section. These variables will be replaced with their values when they appear anywhere in the input workflow file surrounded by *double underscores*. For example:

```yaml
_variables_:
  PROD_BRANCH: master
  STAGING_BRANCH: develop

on:
  push:
    - __PROD_BRANCH__
    - __STAGING_BRANCH__
```

will output:

```yaml
on:
  push:
    - master
    - develop
```

### Special options

In addition to `_defaults_`, there are other options that will affect how the output of certain steps is emitted. These options are parsed from the `_options_` key:

```yaml
_options_:
  use_submodules: true
```

* `use_submodules`: If this is set it will check out code recursively with submodules. This requires two things:
    * A secret called `FLIPPCIRCLECIPULLER_REPO_TOKEN` - Eng Cap will need to add this
    * Your repo needs to have a Git version > 2.18

