import glob

lines = 0
loc = 0
lines_mli = 0
for file in glob.glob("src/*.mli"):
  for line in open(file):
    lines_mli += 1

for file in glob.glob("src/*.ml"):
  for line in open(file):
    lines+=1
    if not (line.strip().startswith("(*") or line.strip() == "" or line.strip().startswith("*")):
      loc += 1

print lines, lines_mli, loc