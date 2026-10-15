# Measured deltas of the density frames (Session 23)

Written by `python tools/qa_sim/density_measure.py 0752c9b --base 5d30659 --write docs/DENSITY_MEASURED.md` from the pairs of `docs/stills/density` (the same run and the same code: `before` has the district's dressing node hidden, `after` shows it).
Luminance is Rec. 709 on 0..1, saturation the HSV S of the pixels brighter than 0.05, contrast the standard deviation of the luminance, over the frame without the parts the HUD still draws; changed share is the part of the pixels
whose luminance differs by 0.05 or more. 55 pairs.

| District | View | Luminance before | after | Saturation before | after | Contrast before | after | Changed share |
|---|---|---|---|---|---|---|---|---|
| gas_station | 01_dark | 0.1616 | 0.1614 | 0.163 | 0.161 | 0.1746 | 0.1747 | 2.7 % |
| gas_station | 02_rest | 0.1344 | 0.1476 | 0.140 | 0.154 | 0.1127 | 0.1305 | 12.9 % |
| gas_station | 03_street | 0.1524 | 0.1565 | 0.107 | 0.109 | 0.1612 | 0.1712 | 7.3 % |
| gas_station | 04_block | 0.1457 | 0.1476 | 0.111 | 0.106 | 0.1337 | 0.1383 | 6.5 % |
| gas_station | 05_skyline | 0.1494 | 0.1523 | 0.114 | 0.114 | 0.1544 | 0.1597 | 5.0 % |
| hospital | 01_dark | 0.1524 | 0.1519 | 0.154 | 0.154 | 0.1624 | 0.1621 | 1.5 % |
| hospital | 02_rest | 0.1032 | 0.1222 | 0.186 | 0.155 | 0.0527 | 0.0855 | 15.6 % |
| hospital | 03_street | 0.1447 | 0.1485 | 0.159 | 0.158 | 0.1404 | 0.1489 | 5.1 % |
| hospital | 04_block | 0.1527 | 0.1556 | 0.208 | 0.213 | 0.1450 | 0.1503 | 3.8 % |
| hospital | 05_skyline | 0.1291 | 0.1384 | 0.171 | 0.164 | 0.1106 | 0.1347 | 9.0 % |
| industrial | 01_dark | 0.1808 | 0.1782 | 0.157 | 0.155 | 0.1823 | 0.1786 | 7.1 % |
| industrial | 02_rest | 0.1140 | 0.1357 | 0.126 | 0.116 | 0.0373 | 0.0786 | 20.7 % |
| industrial | 03_street | 0.1713 | 0.1495 | 0.110 | 0.130 | 0.1695 | 0.1180 | 19.0 % |
| industrial | 04_block | 0.1858 | 0.1603 | 0.122 | 0.182 | 0.1810 | 0.1283 | 22.5 % |
| industrial | 05_skyline | 0.1704 | 0.1453 | 0.119 | 0.159 | 0.1683 | 0.1080 | 19.0 % |
| park | 01_dark | 0.1694 | 0.1683 | 0.151 | 0.151 | 0.1986 | 0.1981 | 2.1 % |
| park | 02_rest | 0.0979 | 0.1238 | 0.138 | 0.120 | 0.0310 | 0.0833 | 17.6 % |
| park | 03_street | 0.1512 | 0.1562 | 0.099 | 0.099 | 0.1641 | 0.1743 | 7.3 % |
| park | 04_block | 0.1473 | 0.1527 | 0.122 | 0.122 | 0.1505 | 0.1597 | 4.7 % |
| park | 05_skyline | 0.1473 | 0.1497 | 0.101 | 0.102 | 0.1623 | 0.1676 | 4.6 % |
| police | 01_dark | 0.1501 | 0.1501 | 0.155 | 0.154 | 0.1448 | 0.1448 | 4.2 % |
| police | 02_rest | 0.1090 | 0.1260 | 0.165 | 0.144 | 0.0539 | 0.0793 | 16.1 % |
| police | 03_street | 0.1517 | 0.1539 | 0.154 | 0.150 | 0.1425 | 0.1485 | 9.1 % |
| police | 04_block | 0.1459 | 0.1485 | 0.200 | 0.195 | 0.1253 | 0.1305 | 6.2 % |
| police | 05_skyline | 0.1395 | 0.1408 | 0.160 | 0.157 | 0.1200 | 0.1229 | 5.7 % |
| power_station | 01_dark | 0.1895 | 0.1864 | 0.129 | 0.128 | 0.2057 | 0.2006 | 7.9 % |
| power_station | 02_rest | 0.1098 | 0.1314 | 0.159 | 0.132 | 0.0393 | 0.0802 | 20.0 % |
| power_station | 03_street | 0.2163 | 0.2267 | 0.120 | 0.130 | 0.2357 | 0.2179 | 27.3 % |
| power_station | 04_block | 0.1754 | 0.1540 | 0.189 | 0.245 | 0.1687 | 0.1286 | 21.6 % |
| power_station | 05_skyline | 0.1746 | 0.1465 | 0.145 | 0.190 | 0.1815 | 0.1159 | 19.0 % |
| residential | 01_dark | 0.1707 | 0.1695 | 0.168 | 0.168 | 0.1974 | 0.1957 | 3.1 % |
| residential | 02_rest | 0.1011 | 0.1274 | 0.144 | 0.126 | 0.0325 | 0.0872 | 18.2 % |
| residential | 03_street | 0.1643 | 0.1702 | 0.137 | 0.136 | 0.1759 | 0.1867 | 9.3 % |
| residential | 04_block | 0.1745 | 0.1792 | 0.187 | 0.193 | 0.1812 | 0.1886 | 6.0 % |
| residential | 05_skyline | 0.1602 | 0.1623 | 0.160 | 0.159 | 0.1727 | 0.1759 | 6.4 % |
| school | 01_dark | 0.1565 | 0.1567 | 0.144 | 0.143 | 0.1661 | 0.1665 | 2.5 % |
| school | 02_rest | 0.0972 | 0.1183 | 0.159 | 0.121 | 0.0236 | 0.0689 | 16.8 % |
| school | 03_street | 0.1465 | 0.1513 | 0.128 | 0.125 | 0.1463 | 0.1569 | 6.8 % |
| school | 04_block | 0.1495 | 0.1525 | 0.140 | 0.139 | 0.1443 | 0.1518 | 4.9 % |
| school | 05_skyline | 0.1451 | 0.1461 | 0.118 | 0.116 | 0.1454 | 0.1488 | 4.9 % |
| substation | 01_dark | 0.1808 | 0.1770 | 0.120 | 0.121 | 0.1975 | 0.1886 | 8.2 % |
| substation | 02_rest | 0.1291 | 0.1434 | 0.120 | 0.113 | 0.0984 | 0.1152 | 16.4 % |
| substation | 03_street | 0.1848 | 0.1582 | 0.096 | 0.124 | 0.2111 | 0.1454 | 19.2 % |
| substation | 04_block | 0.1490 | 0.1306 | 0.119 | 0.169 | 0.1312 | 0.0920 | 20.8 % |
| substation | 05_skyline | 0.1556 | 0.1311 | 0.095 | 0.143 | 0.1616 | 0.0967 | 17.6 % |
| suburbs | 01_dark | 0.1698 | 0.1694 | 0.157 | 0.156 | 0.1963 | 0.1963 | 2.8 % |
| suburbs | 02_rest | 0.1097 | 0.1319 | 0.127 | 0.132 | 0.0615 | 0.0999 | 18.7 % |
| suburbs | 03_street | 0.1642 | 0.1690 | 0.109 | 0.110 | 0.1844 | 0.1919 | 11.1 % |
| suburbs | 04_block | 0.1427 | 0.1457 | 0.123 | 0.121 | 0.1350 | 0.1424 | 5.6 % |
| suburbs | 05_skyline | 0.1408 | 0.1527 | 0.110 | 0.108 | 0.1376 | 0.1654 | 13.1 % |
| warehouses | 01_dark | 0.1816 | 0.1781 | 0.134 | 0.135 | 0.1812 | 0.1760 | 7.9 % |
| warehouses | 02_rest | 0.1173 | 0.1371 | 0.119 | 0.114 | 0.0471 | 0.0823 | 18.9 % |
| warehouses | 03_street | 0.1731 | 0.1550 | 0.099 | 0.110 | 0.1779 | 0.1352 | 18.1 % |
| warehouses | 04_block | 0.1620 | 0.1416 | 0.115 | 0.178 | 0.1436 | 0.0988 | 21.6 % |
| warehouses | 05_skyline | 0.1664 | 0.1429 | 0.110 | 0.144 | 0.1591 | 0.1024 | 19.2 % |

| View | Pairs | Luminance delta | Saturation delta | Contrast delta | Changed share |
|---|---|---|---|---|---|
| 01_dark | 11 | -0.0015 | -0.0006 | -0.0023 | 4.5 % |
| 02_rest | 11 | +0.0202 | -0.0143 | +0.0364 | 17.4 % |
| 03_street | 11 | -0.0023 | +0.0057 | -0.0104 | 12.7 % |
| 04_block | 11 | -0.0056 | +0.0207 | -0.0118 | 11.3 % |
| 05_skyline | 11 | -0.0064 | +0.0140 | -0.0159 | 11.2 % |

District spread: the root-mean-square distance (0..1) between the 48 x 27 thumbnails of two districts' frames of one view, the mean over the 55 pairs of districts and the pair that is least apart.

| View | Baseline (5d30659) mean | least apart | Dressing hidden mean | least apart | Dressing shown mean | least apart |
|---|---|---|---|---|---|---|
| 01_dark | 0.0660 | 0.0247 (hospital, school) | 0.0481 | 0.0197 (residential, suburbs) | 0.0472 | 0.0242 (residential, suburbs) |
| 02_rest | 0.0967 | 0.0388 (park, residential) | 0.0518 | 0.0100 (park, school) | 0.0458 | 0.0177 (park, residential) |
| 03_street | 0.0709 | 0.0263 (hospital, school) | 0.0805 | 0.0284 (hospital, school) | 0.0884 | 0.0343 (hospital, school) |
| 04_block | 0.0838 | 0.0560 (gas_station, warehouses) | 0.0821 | 0.0525 (gas_station, warehouses) | 0.0869 | 0.0510 (substation, warehouses) |
| 05_skyline | 0.0573 | 0.0406 (industrial, warehouses) | 0.0614 | 0.0399 (gas_station, warehouses) | 0.0670 | 0.0376 (industrial, warehouses) |
