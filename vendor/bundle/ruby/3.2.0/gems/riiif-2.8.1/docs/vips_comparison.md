# Benchmarks comparing Vips, Imagemagick, and Graphicsmagick

The following benchmarks were run using ApacheBench v. 2.3 on Ubuntu / Windows Subsystem for Linux (WSL) on a 32 GB (RAM) laptop.

To generate the tables below, a simple resize `curl` command (more details below) was run 50 times in a row and the median response time was calculated.

## Testing with a JPEG

For a 4264 x 3282 jpeg image (26.8 MB)

| Software Used  | Median processing time (ms) | Mean processing time (ms) |
| ---------------|-----------------------------|---------------------------|
| Imagemagick    | 753                         | 753                       |
| Graphicsmagick | 662                         | 660                       |
| Vips           | 79                          | 78                        |

## Testing with a TIFF

For a 7800 x 5865 tif image (7.11 MB)

| Software Used  | Median processing time (ms) | Mean processing time (ms) |
| ---------------|-----------------------------|---------------------------|
| Imagemagick    | 1091                        | 1089                      |
| Graphicsmagick | 800                         | 796                       |
| Vips           | 130                         | 139                       |

## More Resources & Discussion

Those interested in more comprehensive benchmarking with Ruby may be interested in the [vips-benchmarks](https://github.com/jcupitt/vips-benchmarks?tab=readme-ov-file) code repository, which also tests memory usage.

Glen Robson, Stefano Cossu, Ruven Pillay, and Michael D. Smith have written an [excellent article comparing the speed of different image processing tools and formats in a IIIF context](https://journal.code4lib.org/articles/17596). They write, "The testing clearly shows that tiled multi-resolution pyramid TIFF is the fastest format for IIIF, but it comes at a cost of significantly more storage space compared to both HTJ2K [([High Throughput JPEG2000](https://jpeg.org/jpeg2000/htj2k.html))] and JP2." The latter two standards are used by [Kakadu](https://kakadusoftware.com/), a proprietary image toolkit that is commonly used for IIIF servers.

Based on their results, institutions/organizations that use large TIFFs as the base image for IIIF derivatives will likely see the best performance using vips. Conversely, institutions/organizations that use JP2 images will get the best performance using Kakadu HTJ2K.

## Command and Detailed Results for JPGs

Command: `ab -n 50 'http://localhost:3000/images/irises/full/!500,500/0/default.jpg'`

### Using imagemagick

```
Document Path:          /images/irises/full/!500,500/0/default.jpg
Document Length:        79018 bytes

Concurrency Level:      1
Time taken for tests:   37.655 seconds
Complete requests:      50
Failed requests:        0
Total transferred:      3995500 bytes
HTML transferred:       3950900 bytes
Requests per second:    1.33 [#/sec] (mean)
Time per request:       753.097 [ms] (mean)
Time per request:       753.097 [ms] (mean, across all concurrent requests)
Transfer rate:          103.62 [Kbytes/sec] received

Connection Times (ms)
min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:   701  753  28.6    753     813
Waiting:      701  753  28.6    753     813
Total:        701  753  28.6    753     813

Percentage of the requests served within a certain time (ms)
50%    753
66%    768
75%    774
80%    778
90%    794
95%    810
98%    813
99%    813
100%    813 (longest request)
```

### Using graphicsmagick

```
Document Path:          /images/irises/full/!500,500/0/default.jpg
Document Length:        78992 bytes

Concurrency Level:      1
Time taken for tests:   33.131 seconds
Complete requests:      50
Failed requests:        0
Total transferred:      3994173 bytes
HTML transferred:       3949600 bytes
Requests per second:    1.51 [#/sec] (mean)
Time per request:       662.629 [ms] (mean)
Time per request:       662.629 [ms] (mean, across all concurrent requests)
Transfer rate:          117.73 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:   539  662  64.9    660     847
Waiting:      539  662  64.9    660     847
Total:        539  663  65.0    660     848

Percentage of the requests served within a certain time (ms)
  50%    660
  66%    685
  75%    703
  80%    720
  90%    739
  95%    775
  98%    848
  99%    848
 100%    848 (longest request)
```

### Using libvips

```
Document Path:          /images/irises/full/!500,500/0/default.jpg
Document Length:        77647 bytes

Concurrency Level:      1
Time taken for tests:   3.920 seconds
Complete requests:      50
Failed requests:        0
Total transferred:      3926860 bytes
HTML transferred:       3882350 bytes
Requests per second:    12.75 [#/sec] (mean)
Time per request:       78.409 [ms] (mean)
Time per request:       78.409 [ms] (mean, across all concurrent requests)
Transfer rate:          978.16 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:    67   78   5.5     79      90
Waiting:       67   78   5.5     79      90
Total:         67   78   5.5     79      90

Percentage of the requests served within a certain time (ms)
  50%     79
  66%     81
  75%     81
  80%     82
  90%     86
  95%     88
  98%     90
  99%     90
 100%     90 (longest request)
```

## Command and Detailed Results for TIFFs

Command: `ab -n 50 'http://localhost:3000/images/big/full/!500,500/0/default.jpg'`

### Using imagemagick

```
Document Path:          /images/big/full/!500,500/0/default.jpg
Document Length:        82826 bytes

Concurrency Level:      1
Time taken for tests:   54.537 seconds
Complete requests:      50
Failed requests:        0
Total transferred:      4185950 bytes
HTML transferred:       4141300 bytes
Requests per second:    0.92 [#/sec] (mean)
Time per request:       1090.745 [ms] (mean)
Time per request:       1090.745 [ms] (mean, across all concurrent requests)
Transfer rate:          74.96 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:  1004 1091  39.8   1089    1163
Waiting:     1004 1091  39.8   1089    1163
Total:       1004 1091  39.8   1089    1163

Percentage of the requests served within a certain time (ms)
  50%   1089
  66%   1113
  75%   1120
  80%   1139
  90%   1149
  95%   1156
  98%   1163
  99%   1163
 100%   1163 (longest request)
```

### Using graphicsmagick

```
Document Path:          /images/big/full/!500,500/0/default.jpg
Document Length:        82841 bytes

Concurrency Level:      1
Time taken for tests:   39.825 seconds
Complete requests:      50
Failed requests:        0
Total transferred:      4186581 bytes
HTML transferred:       4142050 bytes
Requests per second:    1.26 [#/sec] (mean)
Time per request:       796.495 [ms] (mean)
Time per request:       796.495 [ms] (mean, across all concurrent requests)
Transfer rate:          102.66 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:   642  796  66.2    800     924
Waiting:      642  796  66.2    800     924
Total:        642  796  66.2    800     924

Percentage of the requests served within a certain time (ms)
  50%    800
  66%    832
  75%    845
  80%    859
  90%    880
  95%    899
  98%    924
  99%    924
 100%    924 (longest request)
```

### Using libvips

```
Document Path:          /images/big/full/!500,500/0/default.jpg
Document Length:        81878 bytes

Concurrency Level:      1
Time taken for tests:   6.661 seconds
Complete requests:      50
Failed requests:        0
Total transferred:      4138502 bytes
HTML transferred:       4093900 bytes
Requests per second:    7.51 [#/sec] (mean)
Time per request:       133.222 [ms] (mean)
Time per request:       133.222 [ms] (mean, across all concurrent requests)
Transfer rate:          606.73 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:   115  133  12.0    130     160
Waiting:      115  133  12.0    130     160
Total:        115  133  12.0    130     160

Percentage of the requests served within a certain time (ms)
  50%    130
  66%    141
  75%    143
  80%    146
  90%    150
  95%    154
  98%    160
  99%    160
 100%    160 (longest request)
```