
fbsd2pkg
========

fbsd2pkg performs most of the work of converting a FreeBSD port to a pkgsrc
package.

Some user action is generally required, but in most cases, fbsd2pkg provides
a pretty good guess that need only be checked or slightly modified.

Anything it does not understand is left in the resulting Makefile as a comment.
