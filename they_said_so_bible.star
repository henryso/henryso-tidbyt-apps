# Bible Verse Of the Day powered by theysaidso.com
#
# Copyright (c) 2022 Henry So, Jr.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Note: this app is subject to theysaidso.com's public, rate-limited API

load('http.star', 'http')
load('render.star', 'render')
load('cache.star', 'cache')
load('encoding/base64.star', 'base64')
load('encoding/json.star', 'json')

URL = 'https://quotes.rest/bible/vod.json'

SCROLL_W = 64
TOP_H = 6
BOTTOM_H = 4
SCROLL_BORDER_W = 8
SCROLL_INNER_W = SCROLL_W - SCROLL_BORDER_W
SCROLL_OUTER_W = SCROLL_INNER_W + 4
SCROLL_COLOR = '#333'

TEXT_COLOR = '#fff'
CITATION_COLOR = '#da0'
ATTRIBUTION_COLOR = '#484'

KEY = 'vod'
TTL = 60 * 60

# Takes static for a static quote (for testing)
def main(config):
    if config.get('static'):
        content = {
            'verse': 'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
            'citation': 'Jn 3:16',
        }
    else:
        content = http.get(URL).json()
        content = content['contents']

        content = cache.get(KEY)
        if content == None:
            print("retrieving verse")
            content = http.get(URL)
            if content.status_code == 200:
                content = content.json()['contents']
                book = content['book']
                content = {
                    'verse': content['verse'],
                    'citation': '%s %s:%s' % (
                        BOOKS.get(book, book),
                        content['chapter'],
                        content['number']
                    ),
                }
                cache.set(KEY, json.encode(content), TTL)
            else:
                print('Server returned %s' % content.status_code)
                content = {
                    'verse': 'Server returned "%s".' % content.status_code,
                    'citation': 'N/A',
                }
        else:
            print("using cache for verse")
            content = json.decode(content)

    verse = content['verse']
    citation = content['citation']

    # try to adjust when the quote is too long
    delay = 100
    if len(verse) > 120:
        delay = 50
        if len(verse) > 240:
            quote = quote[0:(quote.rindex(' ', 0, 240))] + '...'

    # generate the widget for the app
    return render.Root(
        delay = delay,
        child = render.Marquee(
            height = 32,
            # offset it to give some time for the user to read the first line
            offset_start = 24,
            offset_end = 24,
            scroll_direction = 'vertical',
            child = render.Column([
                render.Box(
                    width = SCROLL_W,
                    height = TOP_H,
                    color = SCROLL_COLOR,
                    child = render.Image(TOP),
                ),
                render.Padding(
                    pad = (0, 0, 4, 0),
                    child = render.Padding(
                        pad = (1, 0, 1, 0),
                        color = SCROLL_COLOR,
                        child = render.Padding(
                            color = "#000",
                            pad = 1,
                            child = render.Column([
                                render.WrappedText(
                                    content = verse,
                                    width = SCROLL_INNER_W,
                                    color = TEXT_COLOR,
                                ),
                                render.WrappedText(
                                    content = citation,
                                    width = SCROLL_INNER_W,
                                    color = CITATION_COLOR,
                                    font = 'tom-thumb',
                                ),
                            ]),
                        ),
                    )
                ),
                render.Box(
                    width = SCROLL_W,
                    height = BOTTOM_H,
                    color = SCROLL_COLOR,
                    child = render.Image(BOTTOM),
                ),
                render.Box(
                    height = 8,
                    color = "#000",
                    child = render.Text(
                        content = 'theysaidso.com',
                        color = ATTRIBUTION_COLOR,
                    ),
                ),
            ]),
        ),
    )

TOP = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAGAgMAAAAOBnA8AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB5JREFUCNdjCGBAAawMLqEoIJBBVBRFIIQYAVRDGQANnxQTjxhdkQAAAABJ
RU5ErkJggg==
""")
BOTTOM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAEAgMAAABDztE3AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjEGVAA6KiocgghMEFhR8ayBCAqoEVAFi7CnUDrd9zAAAAAElF
TkSuQmCC
""")

# theysaidso does not include deuterocanonicals/apocrypha
BOOKS = {
    # Old Testament
    'Genesis': 'Gn',
    'Exodus': 'Ex',
    'Leviticus': 'Lv',
    'Numbers': 'Nm',
    'Deuteronomy': 'Dt',
    'Joshua': 'Jos',
    'Judges': 'Jg',
    'Ruth': 'Ru',
    '1 Samuel': '1 Sm',
    '2 Samuel': '2 Sm',
    '1 Kings': '1 Kgs',
    '2 Kings': '2 Kgs',
    '1 Chronicles': '1 Chr',
    '2 Chronicles': '2 Chr',
    'Ezra': 'Ezr',
    'Nehemiah': 'Neh',
    'Esther': 'Est',
    'Job': 'Jb',
    'Psalms': 'Ps',
    'Proverbs': 'Prv',
    'Ecclesiastes': 'Eccl',
    'Song of Songs': 'Sg',
    'Isaiah': 'Is',
    'Jeremiah': 'Jer',
    'Lamentations': 'Lam',
    'Ezekiel': 'Ez',
    'Daniel': 'Dn',
    'Hosea': 'Hos',
    'Joel': 'Jl',
    'Amos': 'Am',
    'Obadiah': 'Ob',
    'Jonah': 'Jon',
    'Micah': 'Mi',
    'Nahum': 'Na',
    'Habakkuk': 'Hb',
    'Zephaniah': 'Zep',
    'Haggai': 'Hg',
    'Zechariah': 'Zec',
    'Malachai': 'Mal',
    # New Testament
    'Matthew': 'Mt',
    'Mark': 'Mk',
    'Luke': 'Lk',
    'John': 'Jn',
    'Acts': 'Acts',
    'Romans': 'Rom',
    '1 Corinthians': '1 Cor',
    '2 Corinthians': '2 Cor',
    'Galatians': 'Gal',
    'Ephesians': 'Eph',
    'Philippians': 'Phil',
    'Colossians': 'Col',
    '1 Thessalonians': '1 Thes',
    '2 Thessalonians': '2 Thes',
    '1 Timothy': '1 Tm',
    '2 Timothy': '2 Tm',
    'Titus': 'Ti',
    'Philemon': 'Phlm',
    'Hebrews': 'Heb',
    'James': 'Jas',
    '1 Peter': '1 Pt',
    '2 Peter': '2 Pt',
    '1 John': '1 Jn',
    '2 John': '2 Jn',
    '3 John': '3 Jn',
    'Jude': 'Jude',
    'Revelation': 'Rev',
}
