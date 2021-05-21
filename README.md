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

## Translation from real world coordinates to image coordinates

### Perspective Matrix

$$
\begin{bmatrix}
x'\\
y'\\
z'
\end{bmatrix}
=
\underbrace{
\begin{bmatrix}
f & 0 & c_x\\
0 & f & c_y\\
0 & 0 & 1
\end{bmatrix}}_{\mathrm{M}_{\text{proj}}}
\begin{bmatrix}
X\\
Y\\
Z\\
1
\end{bmatrix}
\\
u = \frac{x'}{z'}=\frac{1}{s_x}\cdot f\cdot\frac{X}{Z}+c_x\\
v = \frac{y'}{z'}=\frac{1}{s_y}\cdot f\cdot\frac{Y}{Z}+c_y
$$

$f$ is focal length

$c_x$ and $c_y$ are centre of image

### 2D-Euclidean-Transformation Matrix

$$
\begin{align}
P_C &= \underbrace{R}_{\text{Rotation}}P_W+\underbrace{T}_{\text{translation}}
\\
\quad\\
\begin{bmatrix}
P_C\\
1
\end{bmatrix}
&=
\begin{bmatrix}
R & T\\
0 & 1
\end{bmatrix}
\begin{bmatrix}
P_W\\
1
\end{bmatrix}
\end{align}
$$

