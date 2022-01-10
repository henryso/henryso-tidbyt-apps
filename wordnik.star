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

load('http.star', 'http')
load('render.star', 'render')
load('cache.star', 'cache')
load('encoding/json.star', 'json')

URL = 'https://api.wordnik.com/v4/words.json/wordOfTheDay?api_key='

WORD_COLOR = '#fff'
LINE_COLOR = '#008'
PART_COLOR = '#468'
TEXT_COLOR = '#89b'

KEY = 'wod'
TTL = 60 * 60

# takes 'static' for a static definition and 'api_key' to retrieve a word
def main(config):
    if config.get('static'):
        content = {
            'word': 'incipience',
            'defs': [
                {
                    'text': 'The condition of being incipient; beginning; commencement.',
                    'part': 'noun',
                },
                {
                    'text': 'A beginning, or first stage',
                    'part': 'noun',
                },
            ],
        }
    else:
        content = cache.get(KEY)
        if content == None:
            api_key = config.get('api_key')
            if api_key:
                print("retrieving word")
                content = http.get(URL + api_key)
                if content.status_code == 200:
                    content = content.json()
                    content = {
                        'word': content['word'],
                        'defs': [
                            {
                                'text': definition['text'],
                                'part': definition['partOfSpeech'],
                            }
                            for definition in content['definitions']
                        ],
                    }
                    cache.set(KEY, json.encode(content), TTL)
                else:
                    print('Server returned %s' % content.status_code)
                    content = {
                        'word': 'error %s' % content.status_code,
                        'defs': [
                            {
                                'text': 'the issue where the server returns %s' % content.status_code,
                                'part': 'n/a',
                            },
                        ],
                    }
            else:
                print('api_key was not passed')
                content = {
                    'word': 'no api key',
                    'defs': [
                        {
                            'text': 'the issue where api_key is not passed',
                            'part': 'n/a',
                        },
                    ],
                }
        else:
            print("using cache for word")
            content = json.decode(content)

    word = content['word']
    definitions = content['defs']

    return render.Root(
        delay = 100 if len(definitions) < 3 else 50,
        child = render.Marquee(
            height = 32,
            offset_start = 16,
            offset_end = 16,
            scroll_direction = 'vertical',
            child = render.Column(flatten([
                render.Text(
                    color = WORD_COLOR,
                    font = 'tb-8' if len(word) < 14 else 'tom-thumb',
                    content = word,
                ),
                [
                    (
                        render.Box(
                            width = 64,
                            height = 1,
                            color = LINE_COLOR,
                        ),
                        render_definition(d),
                    ) for d in definitions
                ]
            ])),
        )
    )

# Returns the widget for a given definition
# definition - the definition
def render_definition(definition):
    part = definition['part'] # #58a
    part = '%s,' % PARTS.get(part, part)
    text = definition['text']
    return render.Stack([
        render.WrappedText(
            width = 64,
            color = TEXT_COLOR,
            content = '%s %s' % (part, text),
        ),
        render.Text(
            color = PART_COLOR,
            content = part,
        ),
    ])

# Flattens a list or tuple of lists or tuples into a single list
# item - the item to flatten
def flatten(item):
    if type(item) == 'list' or type(item) == 'tuple':
        result = []
        for elem in item:
            result += flatten(elem)
        return result
    else:
        return [ item ]

PARTS = {
    'noun':                     'n.',
    'adjective':                'adj.',
    'verb':                     'v.',
    'adverb':                   'adv.',
    'interjection':             'int.',
    'pronoun':                  'pron.',
    'preposition':              'prep.',
    'abbreviation':             'abbr.',
    'affix':                    'aff.',
    'article':                  'art.',
    'auxiliary-verb':           'v.',
    'conjunction':              'conj.',
    'definite-article':         'art.',
    'idiom':                    'id.',
    'imperative':               'imp.',
    'noun-plural':              'n.',
    'noun-posessive':           'n.',
    'past-participle':          'part.',
    'phrasal-prefix':           'phr.',
    'proper-noun':              'n.',
    'proper-noun-plural':       'n.',
    'proper-noun-posessive':    'n.',
    'suffix':                   'suf.',
    'verb-intransitive':        'v.',
    'verb-transitive':          'v.',
}
