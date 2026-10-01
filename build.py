# Builds the page from src.html: index.html for the Mac app (fonts bundled), budget.html for the claude.ai page
dark, light, mottle, paper = open("cork.css.txt").read().split("\n")
s = open("src.html").read()
s = s.replace("CORK_DARK", dark).replace("CORK_LIGHT", light).replace("CORK_MOTTLE", mottle).replace("CORK_PAPER", paper)
head = s[s.index("<!--HEAD-->") + 11 : s.index("<!--/HEAD-->")]
body = s[s.index("<body>") + 6 : s.index("</body>")]
open("budget.html", "w").write(head.strip() + "\n" + body.strip() + "\n")
# The app works offline: swap the Google Fonts links for the bundled font files
start = s.index('<link rel="preconnect"'); end = s.index(">", s.index('<link rel="stylesheet"')) + 1
app = s[:start] + "<style>\n" + open("fonts/fonts.css").read() + "\n</style>" + s[end:]
open("index.html", "w").write(app)
