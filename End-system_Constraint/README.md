## End-system Constraint

In order to effectively evaluate the proposed end-system constraints (EC), we have reproduced the algorithm ITP (Injection Time Planning). 

Please include this citation if you use the reproduced codes as part of your project:

```
@inproceedings{DBLP:conf/infocom/YanQJS20,
  author    = {Jinli Yan and
               Wei Quan and
               Xuyan Jiang and
               Zhigang Sun},
  title     = {Injection Time Planning: Making {CQF} Practical in Time-Sensitive
               Networking},
  booktitle = {39th {IEEE} Conference on Computer Communications, {INFOCOM} 2020,
               Toronto, ON, Canada, July 6-9, 2020},
  pages     = {616--625},
  publisher = {{IEEE}},
  year      = {2020},
  url       = {https://doi.org/10.1109/INFOCOM41043.2020.9155434},
  doi       = {10.1109/INFOCOM41043.2020.9155434},
  timestamp = {Fri, 26 Feb 2021 08:55:14 +0100},
  biburl    = {https://dblp.org/rec/conf/infocom/YanQJS20.bib},
  bibsource = {dblp computer science bibliography, https://dblp.org}
}
```

### Files Organization

  - `tsn-sched-line/`: line topology.
  - `tsn-sched-line/`: ring topology.
  - `tsn-sched-line/`: snowflake topology.

### Usage

The following commands will generate test result.

```
cd ./tsn-sched-line/
make clean
make
./tsn_sched
```
