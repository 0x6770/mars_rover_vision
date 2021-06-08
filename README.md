# EEE2Rover

```bash
# compile
quartus_sh --flow compile DE10_LITE_D8M_VIP

# configure sof
nios2_command_shell nios2-configure-sof DE10_LITE_D8M_VIP_time_limited.sof

# downlaod elf
nios2_command_shell nios2-download demo_batch/D8M_Camera_Test.elf -c 1 -g

# nios2-terminal
nios2-terminal -c 1
```



## Find coordinates in real world

Diagonal of the bounding box is used as a measure of the object size in image($s'$). 

Diagonal is $\sqrt{2}$ of the root mean square of the widths of a rectangle.
$$
\begin{align}
d &= \mathrm{constant} \cdot s'\\
x &= x' \cdot \frac{s}{s'}\\
y &= y' \cdot \frac{s}{s'}\\
z &= d^2-x^2-y^2
\end{align}
$$
<img src="/home/yujie/Downloads/coordinates_real.png" alt="coordinates_real" style="zoom: 33%;" />

<img src="/home/yujie/Downloads/coordinates_picture.png" alt="coordinates_picture" style="zoom:33%;" />

