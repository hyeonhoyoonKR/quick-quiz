import json

f = open('quiztext.txt', 'r')
raw = [_.replace('#', '').replace('*', '').strip().split('\n') for _ in list(f.read().split('---'))]
final = [
	{
		"title": item[0].split(':')[-1].strip(),
		"quiz": [_[:_.find('(') + 1] + _[_.find(')'):] for _ in item[1:]],
		"answer": [_[_.find('(') + 1 : _.find(')')] for _ in item[1:]]
	} for item in raw
]

# print(final[3])

out = open('quiz.json', 'w')
out.write(json.dumps(final, ensure_ascii=False))

f.close()
out.close()
