# DetChip
A Deterministic Embedded End-system Tightly Coupled with TSN Schedule.

<div align="center"><img src="Doc/DetChipArc.svg" alt="DetChip architecture overview" width=370></div>

DetChip (Deterministic Chip) is a deterministic on-chip architecture for embedded end-systems in Time-Sensitive Networking (TSN)[1]. Based on DetChip, we formalize the execution ability of end-systems as end-system constraints (ECs) to co-schedule end-systems and the TSN network. This repository includes the Verilog code implementing DetChip, the software testing usecases, and ITP[2]-based ECs implementation. 


## Files in this Repository

#### Doc/

Design details of DetChip.

#### End-system_Constraints/

Proposed constants.

#### Hardware/

Verilog source codes of Detchip.

#### Software/

Testing usecases.


## Citation
Please include this citation if you use this work as part of your project:

```
@article{journals/tcad/DetChip23,
  author={Li, Chenglong and Li, Zonghui and Li, Tao and Li, Cunlu and Wang, Baosheng},
  journal={IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems}, 
  title={A Deterministic Embedded End-System Tightly Coupled With TSN Schedule}, 
  year={2023},
  volume={42},
  number={11},
  pages={3707-3719},
  doi={10.1109/TCAD.2023.3248500}}
```

## References

[1] IEEE 802.1 TSN TG. Time-Sensitive Networking [URL](https://1.ieee802.org/tsn/).

[2] Jinli Yan, Wei Quan, Xuyan Jiang and Zhigang Sun, "Injection Time Planning: Making CQF Practical in Time-Sensitive Networking," IEEE INFOCOM 2020 - IEEE Conference on Computer Communications, 2020, pp. 616-625, doi: 10.1109/INFOCOM41043.2020.9155434.
