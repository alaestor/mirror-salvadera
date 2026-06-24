# localvocal

A quick and dirty hack to give give the gift of (Hal9000's) voice to my text editor.

Batteries **NOT** included.

---

Expects `~/.local/share/localvocal/pocket-tts-full/` to contain fully-featured [github:kyutai-labs/pocket-tts](https://github.com/kyutai-labs/pocket-tts) model:
```
model.safetensors
pocket-tts.config.yaml
tokenizer.model
```

Also requires a ~20 second voice sample be placed in `~/.local/share/localvocal/samples/` and the name be changed in the python files (hardcoded)
