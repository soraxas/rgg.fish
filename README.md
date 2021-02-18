# What does it do

A lightweight **fish function**  wrapper around `rg` where it stores the search results in a global variable (persists within the same shell) and you can quickly open the file in your favourite editor (`$EDITOR`, i.e., `vim`) at the specific linenumber with a simple
```sh
vv 2-45
```

For example:
```sh
$ rgg settings
> [1]: HACKING.md
> 1-67:  `ranger/container/settings.py` in alphabetical order.
> 1-71:The setting is now accessible with `self.settings.my_option`, > assuming self is a
> 
> [2]: examples/plugin_file_filter.py
> 2-20:    if not fobj.fm.settings.show_hidden and fobj.path in HIDE_FILES:
> 
...
> 
> [35]: ranger/ext/vcs/vcs.py
> 35-73:        self.repotypes_settings = set(
> 35-75:            if getattr(dirobj.settings, values['setting']) in > ('enabled', 'local')
> 35-138:        for repotype in self.repotypes_settings:


$ vv
> Usage: vv [FILE_NUMBER[-LINE_NUMBER]]
> 
> Previously stored search results:
> [Arg]	[LinesNum]    	[Filename]
> 1-XX	67..71  (2)	    HACKING.md
> 2-XX	20..20  (1)	    examples/plugin_file_filter.py
...
> 35-XX	73..138 (3)	    ranger/ext/vcs/vcs.py


$ vv 35     # opens vim with `vim ranger/ext/vcs/vcs.py`
$ vv 35-75  # opens vim with `vim ranger/ext/vcs/vcs.py +75`
$ vv 35-100 # wstill works even if line number does not appear in search result
```

It comes with nice fish completions too:)

# Install
```sh
fisher add soraxas/rgg
```