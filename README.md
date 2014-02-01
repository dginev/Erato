Erato is the ancient greek muse of love and poetry.

Action Plan
====

0. Empty page with Facebook login button -> upon login:
1. Facebook API - obtain top 10 artists of user
  * https://developers.facebook.com/docs/graph-api/reference/user/music

2. Lyrics::Fetcher API - obtain lyrics for each artist (keep scores in DB, to avoid repeating work)

3. Term extraction - identify terms using Yahoo APIs
  ```
  query.yahooapis.com/v1/public/yql?q=select * from contentanalysis.analyze where text='Maybe if I write enough, I will hear about an Italian sculptor.'&format=json&diagnostics=false
  ```

4. Use some of the publicly available word frequency lists, e.g. http://invokeit.wordpress.com/frequency-word-lists/
5. Score = <hipsterness, literacy, coolness, terms>
  * rare words / all words = hipsterness
  * unique words / all words = literacy
  * trending words / all words = coolness
  * terms are like icing on the cake (?)
 (logarithmic computations will definitely work best)

6. Display score and plot the amplitude progression between songs/artists?
7. (Maybe) Suggestions to the user: Higher rated/lower rated songs. (expand horizons / indulge in similarity)

Notes:
====
  * 20:30 to 21:01 - found and patched a bug with Lyrics::Fetcher::AZLyrics, should remind myself to file a GitHub patch!
