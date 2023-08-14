# Used Resources

## Vi favicon
The vi favicon is based on the 
<a href="https://commons.wikimedia.org/wiki/File:Vi_logo.svg" target="blank">Vi logo</a> file
created by DavidL under a <a href="https://creativecommons.org/licenses/by-sa/4.0" target="blank">CC BY-SA 4.0</a> (via Wikimedia Commons).

## Pandoc
I converted the Ex/Vi manpages with Pandoc

* [Pandoc]{:target="blank"}

to Markdown.

[Pandoc]: https://pandoc.org/

```
$ pandoc --from=man --to= markdown -o ex.1.md ex.1
$ pandoc --from=man --to= markdown -o vi.1.md vi.1
```


## Site Creation
My pages are written in Markdown (directory docs) an transformed into HTML 
pages (local directory site). The site data are published in the gh-pages 
branch.

The following Python modules are used to create this site:

* [MkDocs]{:target="blank"}
* [Material for MkDocs]{:target="blank"}
* MkDocs plugin [mkdocs-git-revision-date-localized-plugin]{:target="blank"}

[MkDocs]: https://pypi.org/project/mkdocs/
[Material for MkDocs]: https://pypi.org/project/mkdocs-material/
[mkdocs-git-revision-date-localized-plugin]: https://pypi.org/project/mkdocs-git-revision-date-localized-plugin/

