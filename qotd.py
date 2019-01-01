#!/usr/bin/python3

# Get today's "Quote of the Day" and format it nicely for rendering, send
# the results to stdout, unless the quote is too long, in which case just
# exit with an error status.


import wikiquote
import textwrap
import string

# Get the quote from Wikiquote
(q, a)  = wikiquote.quote_of_the_day()

# Filter out non-printables in both the quote text and the author.
q = '' .join(filter(lambda x: x in string.printable, q))
a = '' .join(filter(lambda x: x in string.printable, a))

# If there are more than 100 words in the quote, skip it and return
# with error.
if (len(q.split()) > 100):
    exit(1)

# Print out a formated version of the quote.
print(textwrap.fill(q, width=55))

# Strip out whitespace from author and print.
print("\n-- %s" %(a.strip()))

exit(0)
