with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# Find where meal-specific images are stored
for term in ['breakfast_image', 'lunch_image', 'dinner_image', 'meal_image', 'bf_image', 'breakfastImage', 'lunchImage', 'dinnerImage']:
    idx = content.find(term)
    if idx != -1:
        print(f'Found {term} at index {idx}')
        print(content[max(0,idx-100):idx+200])
        print('---')
    else:
        print(f'{term}: NOT FOUND')
