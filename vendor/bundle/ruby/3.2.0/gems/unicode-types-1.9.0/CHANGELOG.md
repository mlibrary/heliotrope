## CHANGELOG

### 1.9.0

- Unicode 15.1

### 1.8.0

- Unicode 15.0

### 1.7.0

- Unicode 14

### 1.6.0

- Unicode 13

### 1.5.0

* Unicode 12.1

### 1.4.0

* Unicode 12

### 1.3.0

* Unicode 11
* Do not depend on rubygems (only use zlib stdlib for unzipping)

### 1.2.2

* Explicitly load rubygems/util, fixes regression in 1.2.1

### 1.2.1

* Use `Gem::Util` for `gunzip`, removes deprecation warning

### 1.2.0

* Unicode 10

### 1.1.2

* Fix that surrogates were detected in UTF-8 (regression of 1.1.1)
* Fix bug in index compression scheme

### 1.1.1

* Fix bug that prevented non-UTF-8 encodings from working

### 1.1.0

* Support Unicode 9.0

### 1.0.1

* Fix index that would confuse reserved and noncharacters

### 1.0.0

* Initial release

