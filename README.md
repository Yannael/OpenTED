#### Online interface for browsing/downloading OpenTED data

See [README in `opented` folder](https://github.com/Yannael/OpenTED/tree/master/code)

Online at: 

[http://yleborgne.net/opented](http://yleborgne.net/opented)

#### Reproducibility

* Original CSVs were taken from the [EU Open Data portal](https://data.europa.eu/euodp/en/data/dataset/ted-csv)
* Data preprocessing: https://github.com/Yannael/OpenTED/blob/master/code/preprocessing.ipynb

#### Docker container:
* Clone this repository

```
 git clone https://github.com/Yannael/OpenTED 
```

* [Download parquet files](), untar and store into code folder

```  
 wget litpc45.ulb.ac.be/ted.parquet.tgz
 tar xvzf litpc45.ulb.ac.be/ted.parquet.tgz
 mv ted.parquet code
```

* Build docker container (from docker folder)

```
 cd docker
 docker built -t opented .
```

* Start container (from code folder):

```
 cd code
 docker run -v `pwd`:/srv/shiny-server/opented -p 3838:3838 -it opented bash
```

* From container, start server

```  
 ./startupscript
```

* Application is available in your browser at 127.0.0.1:3838
  
  