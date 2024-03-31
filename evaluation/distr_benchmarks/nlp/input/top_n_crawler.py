import requests
from bs4 import BeautifulSoup

# Don't use this crawler unless you lose the book_links.txt file or want to regerate it.
# Popularity is montly so when you regenerate it expect to see differences.

# Get the top 1000 list
n = 1000
book_links = []
base_url = 'https://www.gutenberg.org'
url = base_url + '/ebooks/search/?sort_order=downloads'

while len(book_links) < n:
    print(f'URL: {url}')
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find the book links
    links = [a['href'] for a in soup.find_all('a', href=True) if a['href'].startswith('/ebooks/')]
    # Last page doesn't have next link
    book_index = 2 if url.endswith('976') else 3
    url = base_url + links[book_index - 1]
    assert 'start_index=' in url, links
    book_links.extend(links[book_index:book_index+25])

book_links = book_links[:n]

with open('book_links.txt', 'w') as file:
    for link in book_links:
        print(link)
        file.write(f'{base_url}{link}\n')

with open('book_txt_links.txt', 'w') as book_txt_links_file:
    with open('book_links.txt', 'r') as book_links_file:
        for line in book_links_file:
            id = line.split('/')[-1].strip()
            book_txt_link = f'https://www.gutenberg.org/cache/epub/{id}/pg{id}.txt'
            print(book_txt_link)
            book_txt_links_file.write(f'{book_txt_link}\n')
