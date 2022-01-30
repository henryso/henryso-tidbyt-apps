# Word Of the Day powered by Wordnik
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

# Note: this app uses the Wordnik API and requires a Wordnik API key to be
# passed as api_key
#
# The Wordnik logo in the background is used with permission.
# Wordnik is at https://wordnik.com
# To get an API key and/or learn about Wordnik's API, go to
# https://developer.wordnik.com

load("http.star", "http")
load("render.star", "render")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

URL = "https://api.wordnik.com/v4/words.json/wordOfTheDay?api_key="

WIDTH = 64
HEIGHT = 32
LOGO_PAD = (0, HEIGHT - 14, 0, 0)

LONG_WORD = 13
LONG_DEFINITION = 25
FAST_DEFINITION = 50

WORD_COLOR = "#fff"
LINE_COLOR = "#008"
SEPARATOR_COLOR = "#035"
PART_COLOR = "#468"
TEXT_COLOR = "#9ac"

KEY = "wod"
TTL = 60 * 60

FONTS = {
    True: ( "tb-8", 8 ),
    False: ( "tom-thumb", 6 )
}

# takes 'static' for a static definition, 'api_key' to retrieve a word, and
# 'hide_logo' (truthy value) if the logo should be hidden
def main(config):
    static = config.get("static")
    if static != None:
        content = STATIC_CONTENT[int(static) % len(STATIC_CONTENT)]
    else:
        content = cache.get(KEY)
        if content == None:
            api_key = config.get("api_key")
            if api_key:
                print("retrieving word")
                content = http.get(URL + api_key)
                if content.status_code == 200:
                    content = content.json()
                    content = {
                        "word": content["word"],
                        "defs": [
                            {
                                "text": definition["text"],
                                "part": definition["partOfSpeech"],
                            }
                            for definition in content["definitions"]
                        ],
                    }
                    cache.set(KEY, json.encode(content), TTL)
                else:
                    print("Server returned %s" % content.status_code)
                    content = {
                        "word": "error %s" % content.status_code,
                        "defs": [
                            {
                                "text": "the issue where the server returns %s" % content.status_code,
                                "part": "n/a",
                            },
                        ],
                    }
            else:
                print("api_key was not passed")
                content = {
                    "word": "no api key",
                    "defs": [
                        {
                            "text": "the issue where api_key is not passed",
                            "part": "n/a",
                        },
                    ],
                }
        else:
            print("using cache for word")
            content = json.decode(content)

    print(content)

    word = content["word"]
    definitions = content["defs"]
    word_font = FONTS[len(word) < LONG_WORD]
    longest_definition_word_length = 0
    definition_word_count = 0
    for d in definitions:
        definition_word_count += 1 # for the part of speech
        for w in d["text"].split():
            definition_word_count += 1
            length = len(list(w.codepoints()))
            if longest_definition_word_length < length:
                longest_definition_word_length = length
    definition_font_is_large = (
        longest_definition_word_length < LONG_WORD and
        definition_word_count < LONG_DEFINITION
    )
    definition_font = FONTS[definition_font_is_large][0]
    delay = 100 if definition_word_count < FAST_DEFINITION else 50

    display = render.Column([
        render.Stack([
            render.Column([
                render.Box(
                    width = WIDTH,
                    height = word_font[1] - 1,
                ),
                render.Box(
                    width = WIDTH,
                    height = 1,
                    color = LINE_COLOR,
                ),
            ]),
            render.Text(
                color = WORD_COLOR,
                font = word_font[0],
                content = word,
            ),
        ]),
        render.Marquee(
            height = HEIGHT - word_font[1],
            offset_start = 16,
            offset_end = 16,
            scroll_direction = "vertical",
            child = render.Column(flatten([
                (
                    render.Box(
                        width = WIDTH,
                        height = 1,
                        color = SEPARATOR_COLOR,
                    ) if d[0] != 0 else tuple(),
                    render_definition(d[1], definition_font),
                ) for d in enumerate(definitions)
            ])),
        ),
    ])

    return render.Root(
        delay = delay,
        child = display if config.get("hide_logo") else render.Stack([
            render.Padding(
                pad = LOGO_PAD,
                child = render.Image(LOGO),
            ),
            display,
        ]),
    )

# Returns the widget for a given definition
# definition - the definition
def render_definition(definition, font):
    part = definition["part"] # #58a
    part = "%s," % PARTS.get(part, part)
    text = definition["text"]
    return render.Stack([
        render.WrappedText(
            width = WIDTH,
            color = TEXT_COLOR,
            content = "%s %s" % (part, text),
            font = font,
        ),
        render.Text(
            color = PART_COLOR,
            content = part,
            font = font,
        ),
    ])

# Flattens a list or tuple of lists or tuples into a single list
# item - the item to flatten
def flatten(item):
    if type(item) == "list" or type(item) == "tuple":
        result = []
        for elem in item:
            result += flatten(elem)
        return result
    else:
        return [ item ]

PARTS = {
    "noun":                     "n.",
    "adjective":                "adj.",
    "verb":                     "v.",
    "adverb":                   "adv.",
    "interjection":             "int.",
    "pronoun":                  "pron.",
    "preposition":              "prep.",
    "abbreviation":             "abbr.",
    "affix":                    "aff.",
    "article":                  "art.",
    "auxiliary-verb":           "v.",
    "conjunction":              "conj.",
    "definite-article":         "art.",
    "idiom":                    "id.",
    "imperative":               "imp.",
    "noun-plural":              "n.",
    "noun-posessive":           "n.",
    "past-participle":          "part.",
    "phrasal-prefix":           "phr.",
    "proper-noun":              "n.",
    "proper-noun-plural":       "n.",
    "proper-noun-posessive":    "n.",
    "suffix":                   "suf.",
    "verb-intransitive":        "v.",
    "verb-transitive":          "v.",
    "transitive verb":          "v.",
}

STATIC_CONTENT = [
    {
        "word": "incipience",
        "defs": [
            {
                "text": "The condition of being incipient; beginning; commencement.",
                "part": "noun",
            },
            {
                "text": "A beginning, or first stage",
                "part": "noun",
            },
        ],
    },
    {
        "word": "heterochromatic",
        "defs": [
            {
                "text": "Of or characterized by different colors; varicolored.",
                "part": "adjective",
            },
            {
                "text": "Consisting of different wavelengths or frequencies.",
                "part": "adjective",
            },
            {
                "text": "Of or relating to heterochromatin.",
                "part": "adjective",
            },
        ],
    },
    {
        "word": "pallasite",
        "defs": [
            {
                "text": "A stony-iron meteorite embedded with glassy crystals of olivine.",
                "part": "noun",
            },
        ],
    },
]

LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAOCAMAAACo5erwAAAAYFBMVEUAAAAHAQARAQAEBwMNBQIV
BQAcBQIJCwcjBQAqBgAbDQA4BQAOEQ0TFRI/CwE2DwQWGBU/EQA3FQAaHBkzGAAdHx1AFwI/HAA8
HwAlJyUrLCovMS4zNTM2ODY6PDk9Pzw+R+8dAAABaklEQVQoz5WT0XbDIAiGzWjqsupma7tFEXj/
txxo0vWc3qxcgeLHDyHO/csgx4cgJvAZ3CvmmR4CkogSXgS0BwWlQvsD+GBiwO8+HNSZe+CzCY05
ewPopR4Eyw0DAMHeVs6aXawCIPuPdb3O67rOUJmEk0cW4aqAIoXULZpG3gC+MSogSdWyTRQTBA/r
ZtcDimDRTKpVHzZXxVyWBI2DAmIT7LqJQSmiMJQ8/2xmACWXnuSxA0hl30ShBrix3ZvpkT5lDoHJ
z5fvYRcF3Jxr3L9f6IBik5E6ANLD8VUoSVOMNummr/OwZUKJDojGdMkAydw7oN03QbWpLhLrxR03
wBsYQPsbCvgJcO/A9AkDlE3T8ql2ProBKFJHjSdA3meohvY08Cg2nRSwTBsASDAllGdAsMluhEQm
BnGTtJzebSlqB0Ybl7S+B70A7wDL2AjQl9Hvyzm9jcPYgT7lHCHq3qQep2A3wQL7q34BfEop1DYa
VFcAAAAASUVORK5CYII=
""")
