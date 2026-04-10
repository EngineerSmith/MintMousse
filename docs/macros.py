import yaml
from pathlib import Path
from mkdocs_macros import MacrosPlugin

def define_env(env):
    @env.macro
    def component_table():
        """Auto-generates the sortable overview table in components/types/*.md"""

        types_dir = Path("docs/components/types")
        rows = []

        for md_file in sorted(types_dir.glob("*.md")):
            if md_file.name == "index.md":
                continue
            content = md_file.read_text(encoding="utf8")
            if content.startswith("---"):
                _, frontmatter, _ = content.split("---", 2)
                try:
                    data = yaml.safe_load(frontmatter.strip())
                except Exception:
                    data = {}
            else:
                data = {}

            type_data = data.get("type", {})

            rows.append({
              "typeName": type_data.get("name", md_file.stem.title()),
              "typeUpdates": type_data.get("updates", 0),
              "typePushes": type_data.get("pushes", 0),
              "typeEvents": type_data.get("events", 0),
              "typeChildren": "✅" if type_data.get("children", false) else "❌",
              "typeDescription": type_data.get("description", ""),
              "link": f"{md_file.stem}.md"
            })

        rows.sort(key=lambda x: x["typeName"].lower())

        table  = "| Type | Updates | Pushes | Events | Children | Description |\n"
        table += "|------|---------|--------|--------|----------|-------------|\n"
        for r in rows:
            table += (
                f"| [{r['typeName']}]({r['link']}) "
                f"| {r['typeUpdates']} "
                f"| {r['typePushes']} "
                f"| {r['typeEvents']} "
                f"| {r['typeChildren']} "
                f"| {r['typeDescription']} |\n"
            )
        return table

