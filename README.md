# mallets


## install

first install mx.samples2:

```
;install https://github.com/schollz/mx-samples2
```

then download the samples:


```
os.execute("mkdir -p ~/dust/audio/mx.samples/marimba_red && curl -L -o ~/dust/audio/mx.samples/marimba_red/download.zip https://github.com/schollz/mx.samples/releases/download/samples/marimba_red.zip && unzip ~/dust/audio/mx.samples/marimba_red/download.zip -d ~/dust/audio/mx.samples/marimba_red/ && rm -rf ~/dust/audio/mx.samples/marimba_red/download.zip")
os.execute("mkdir -p ~/dust/audio/mx.samples/marimba_white && curl -L -o ~/dust/audio/mx.samples/marimba_white/download.zip https://github.com/schollz/mx.samples/releases/download/samples/marimba_white.zip && unzip ~/dust/audio/mx.samples/marimba_white/download.zip -d ~/dust/audio/mx.samples/marimba_white/ && rm -rf ~/dust/audio/mx.samples/marimba_white/download.zip")
```

then install mallets:

```
;install https://github.com/schollz/mallets
```