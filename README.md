This notebook downloads the data used in the article ["Breaching 1.5°C: Give me the odds"](https://everval.github.io/Odds-of-breaching-1.5C/) by J.E. Vera-Valdés and O. Kvist. 
It contains the code used to download the data from the HadCRUT5, GISTEMP, NOAAGlobalTemp, Berkeley Earth, and ONI datasets. 

The rendered notebook can be found [here](https://everval.github.io/Global-Temperature-Anomalies/). It shows the code so that you can easily use whichever dataset you want. The data is downloaded in CSV format and directly accessible from the notebook. 

The temperature data files are also stored in the [`data` folder](https://github.com/everval/Global-Temperature-Anomalies/tree/main/data). Each CSV file contains three columns: `Date`, `RawTemperature`, and `Temp`. 
- The `Date` column contains the date of the temperature anomaly in months. 
- The `RawTemperature` column contains the raw temperature anomaly according to the dataset.
- The `Temp` column contains the temperature anomaly relative to the preindustrial level, defined as the average temperature anomaly from 1850 to 1900. The `Temp` column is calculated by subtracting the preindustrial level from the `RawTemperature` column. 

The ONI dataset contains two columns. 
- The `Date` column in months.
- The `Anom` column containing the ONI anomaly.

The code is written in `Julia` and is organized into sections that correspond to the different datasets. 
Each section downloads the data, processes it, and saves it in a CSV file. The data is then merged into a single dataset that contains the temperature anomalies for each dataset, as well as the ONI data. 

Finally, the notebook includes code to plot the data and highlight El Niño and La Niña events.

If you use this notebook, please cite it as:

Vera-Valdés, J. Eduardo, and Olivia Kvist. 2024. “Breaching 1.5°C: Give Me the Odds.” arXivarXiv:2412.13855. [https://doi.org/10.48550/arXiv.2412.13855](https://doi.org/10.48550/arXiv.2412.13855).

```bibtex
@misc{veravaldes2024breaching,
      title={Breaching 1.5{\deg}C: Give me the odds}, 
      author={J. Eduardo Vera-Valdés and Olivia Kvist},
      year={2024},
      eprint={2412.13855},
      archivePrefix={arXiv},
      primaryClass={stat.AP},
      url={https://arxiv.org/abs/2412.13855}, 
}
```