# Benchmarks demonstrating different backends.

This benchmarks were run on Riiif 2.0.0.beta.  They show the difference in speed in decoding a 5240x7057 pixel jp2 using openjpeg 2.2.0 (via Imagemagick) versus Kakadu 7.10.2.
 
## RIIIF with openjpeg 2.2.0
 
```
$ ab -n 30 'https://localhost:3000/iiif/2/bc%2F151%2Fbq%2F1744%2Fbc151bq1744_00_0001.jp2/full/!400,400/0/default.jpg'

Document Length:        27958 bytes

Concurrency Level:      1
Time taken for tests:   326.297 seconds
Complete requests:      30
Failed requests:        0
Total transferred:      855851 bytes
HTML transferred:       838740 bytes
Requests per second:    0.09 [#/sec] (mean)
Time per request:       10876.556 [ms] (mean)
Time per request:       10876.556 [ms] (mean, across all concurrent requests)
Transfer rate:          2.56 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       55  101  52.8     84     298
Processing:  8432 10775 3627.0   9669   26365
Waiting:     8420 10642 3395.2   9532   24849
Total:       8489 10876 3626.9   9724   26442

Percentage of the requests served within a certain time (ms)
  50%   9724
  66%  10197
  75%  10537
  80%  11088
  90%  15837
  95%  18224
  98%  26442
  99%  26442
 100%  26442 (longest request)
 ```
 
 ## RIIIF, no cache, kakadu + imagemagick
 ```
 ab -n 30 'https://localhost:3000/iiif/2/bc%2F151%2Fbq%2F1744%2Fbc151bq1744_00_0001.jp2/full/!400,400/0/default.jpg'
 Document Length:        27978 bytes

Concurrency Level:      1
Time taken for tests:   82.646 seconds
Complete requests:      30
Failed requests:        0
Total transferred:      856440 bytes
HTML transferred:       839340 bytes
Requests per second:    0.36 [#/sec] (mean)
Time per request:       2754.880 [ms] (mean)
Time per request:       2754.880 [ms] (mean, across all concurrent requests)
Transfer rate:          10.12 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       49   95  65.4     78     398
Processing:  1991 2660 431.4   2643    4207
Waiting:     1943 2583 415.3   2565    4033
Total:       2096 2755 448.5   2721    4395

Percentage of the requests served within a certain time (ms)
  50%   2721
  66%   2820
  75%   2944
  80%   2975
  90%   3260
  95%   3486
  98%   4395
  99%   4395
 100%   4395 (longest request)
 ```
