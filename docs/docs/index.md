# sc-portable

A portable offline version of the [suttacentral](https://suttacentral.net/) website that can be downloaded as a single file and executed across multiple platforms and devices (using [redbean](https://redbean.dev/)).

## Quickstart

!!! note
    This is still experimental.

### Download

Choose a version with the languages you are interested in below.

{{binaries_table}}

Additionally, you can (optionally) download an associated database file (must be the same language combination you downloaded above) which activates the search functionality for those languages.

{{search_table}}

Please note that you **must** place this file into the same folder as the ".com" executable to make it work.

### Usage

**Windows / Mac (not tested)**

Click on the ".com" file to execute it. You might need to allow some firewall settings that is prompted. Then open [http://localhost:8080](http://localhost:8080) in your browser.


**Linux**

You can simply run:

```
chmod +x sc-portable_<version>.com
bash -c "./sc-portable_<version>.com"
```

Then open [http://localhost:8080](http://localhost:8080) in your browser.

## Known Errors/Limitations

- Only the sutta section is working and only in the language(s) chosen
- The loading animation runs indefinetly sometimes
- Dictionary lookup works in text, but not in search or when clicking on the page of word
- The search can show characters with inproper encoding
- The search can only in english apply "stemming"
- Trying to reload the page and/or clearing the site cache sometimes helps resolving issues
