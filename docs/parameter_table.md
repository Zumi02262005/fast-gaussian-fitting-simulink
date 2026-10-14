<div style="font-family: 'Monocraft', monospace;">
<h1>Parameter Table</h1>
<table>
    <thead>
        <tr>
            <th align="left">Group</th>
            <th align="left">Parameter</th>
            <th align="center">Symbol</th>
            <th align="left">Value</th>
            <th align="left">Unit</th>
            <th align="left" style="min-width: 250px;">Sweep Range</th>
            <th align="left" style="min-width: 250px;">Source and Notes</th>
        </tr>
    </thead>
    <tbody>
        <!-- Group 1: Sensor -->
        <tr>
            <td rowspan="6" align="left" style="color: orange;"><strong>Sensor</strong></td>
            <td>Pixel Pitch</td>
            <td align="center"><em>a</em></td>
            <td align="left" style="color: cyan;">5.5</td>
            <td align="center">um</td>
            <td align="center">NaN</td>
            <td align="left">Tang et al.</td>
        </tr>
        <tr>
            <td>ROI size</td>
            <td align="center"><em>NxN</em></td>
            <td align="left" style="color: cyan;">7</td>
            <td align="center">pixels</td>
            <td align="center">NaN</td>
            <td align="left">Assumed</td>
        </tr>
        <tr>
            <td>ADC Bit Depth</td>
            <td align="center"><em>b</em></td>
            <td align="left" style="color: cyan;">8</td>
            <td align="center">bits</td>
            <td align="center">NaN</td>
            <td align="left">Tang et al.</td>
        </tr>
        <tr>
            <td>Full-well Capacity</td>
            <td align="center"></td>
            <td align="left" style="color: cyan;">13500</td>
            <td align="center">e<sup>-</sup></td>
            <td align="center">NaN</td>
            <td align="left">Sets Saturation; Wei et al.</td>
        </tr>
        <tr>
            <td>Gain</td>
            <td align="center"><em>g</em></td>
            <td align="left" style="color: cyan;">52.7</td>
            <td align="center">e<sup>-</sup>/DN</td>
            <td align="center">NaN</td>
            <td align="left">Electrons per Digital Number; Derived from Wei et al.</td>
        </tr>
        <tr>
            <td>Quantum Efficiency</td>
            <td align="center"><em>η</em></td>
            <td align="left" style="color: cyan;">0.6</td>
            <td align="center">fraction</td>
            <td align="center">NaN</td>
            <td align="left">Wei et al.</td>
        </tr>
        <!-- Group 2: Optics -->
        <tr>
            <td rowspan="3" align="left" style="color: magenta;"><strong>Optics</strong></td>
            <td>Focal length</td>
            <td align="center"><em>f</em></td>
            <td align="left" style="color: cyan;">42</td>
            <td align="center">mm</td>
            <td align="center">NaN</td>
            <td align="left">Tang et al.</td>
        </tr>
        <tr>
            <td>PSF width</td>
            <td align="center"><em>σ</em></td>
            <td align="left" style="color: cyan;">0.7</td>
            <td align="center">pixels</td>
            <td align="center" style="color: cyan;">[0.5, 0.7, 1.0, 1.5]</td>
            <td align="left">Wei et al.</td>
        </tr>
        <tr>
            <td>PSF model</td>
            <td align="center"></td>
            <td align="left" style="color: cyan;">gaussian</td>
            <td align="center">category</td>
            <td align="center" style="color: cyan;">{gaussian, airy disk, moffat}</td>
            <td align="left">Trujillo et al., Nahlik & Stys</td>
        </tr>
        <!-- Group 3: Star -->
        <tr>
            <td rowspan="2" align="left" style="color: #2ea043;"><strong>Star</strong></td>
            <td>Total signal</td>
            <td align="center"><em>S</em></td>
            <td align="left" style="color: cyan;">5000</td>
            <td align="center">e<sup>-</sup></td>
            <td align="center" style="color: cyan;">[1000, 2000, 5000, 10000, 20000, 30000]</td>
            <td align="left">Derived from Wei et al.</td>
        </tr>
        <tr>
            <td>True centroid</td>
            <td align="center"><em>(x<sub>c</sub>, y<sub>c</sub>)</em></td>
            <td align="left" style="color: cyan;">Drawn Per Trial</td>
            <td align="center">pixels</td>
            <td align="center">NaN</td>
            <td align="left">NaN</td>
        </tr>
        <!-- Group 4: Noise -->
        <tr>
            <td rowspan="3" align="left" style="color: red;"><strong>Noise</strong></td>
            <td>Dark current</td>
            <td align="center"><em>D</em></td>
            <td align="left" style="color: cyan;">125</td>
            <td align="center">e<sup>-</sup>/pixel/s</td>
            <td align="center">NaN</td>
            <td align="left">Wei et al.</td>
        </tr>
        <tr>
            <td>Read noise</td>
            <td align="center"><em>σr</em></td>
            <td align="left" style="color: cyan;">13</td>
            <td align="center">e<sup>-</sup>rms</td>
            <td align="center">NaN</td>
            <td align="left">Wei et al.</td>
        </tr>
        <tr>
            <td>Exposure time</td>
            <td align="center"><em>t</em></td>
            <td align="left" style="color: cyan;">100</td>
            <td align="center">ms</td>
            <td align="center">NaN</td>
            <td align="left">Tang et al.</td>
        </tr>
        <!-- Group 5: Simulation -->
        <tr>
            <td rowspan="2" align="left" style="color: yellow;"><strong>Simulation</strong></td>
            <td>Trials per Setting</td>
            <td align="center"><em>N</em></td>
            <td align="left" style="color: cyan;">10000</td>
            <td align="center">count</td>
            <td align="center">NaN</td>
            <td align="left">Wan et al.</td>
        </tr>
        <tr>
            <td>Random seed</td>
            <td align="center"></td>
            <td align="left" style="color: cyan;">123</td>
            <td align="center">integer</td>
            <td align="center">NaN</td>
            <td align="left">Fixed for reproducibility</td>
        </tr>
    </tbody>
</table>