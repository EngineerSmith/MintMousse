import yaml
from pathlib import Path

def define_env(env):
    @env.macro
    def components_table():
        """Auto-generates the sortable overview table in components/types/*.md"""

        types_dir = Path("docs/components/types")
        rows = []

        for md_file in sorted(types_dir.glob("*.md")):
            if md_file.name == "index.md":
                continue
            content = md_file.read_text(encoding="utf-8")
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
              "typeChildren": "✅" if type_data.get("children", False) else "❌",
              "typeDescription": type_data.get("description", ""),
              "link": f"{md_file.stem}.md"
            })

        rows.sort(key=lambda x: x["typeName"].lower())

        html = """<div class="md-typeset__table">
<table><thead><tr>
    <th style="width: 180px;">Type</th>
    <th style="width: 88px; text-align: center;">Updates</th>
    <th style="width: 88px; text-align: center;">Pushes</th>
    <th style="width: 88px; text-align: center;">Events</th>
    <th style="width: 110px; text-align: center;">Children</th>
    <th>Description</th>
</tr></thead><tbody>"""

        for r in rows:
            html +=  '<tr>\n'
            html += f'    <td><a href="{r["link"]}">{r["typeName"]}</a></td>\n'
            html += f'    <td style="text-align: center;">{r["typeUpdates"]}</td>\n'
            html += f'    <td style="text-align: center;">{r["typePushes"]}</td>\n'
            html += f'    <td style="text-align: center;">{r["typeEvents"]}</td>\n'
            html += f'    <td style="text-align: center;">{r["typeChildren"]}</td>\n'
            html += f'    <td>{r["typeDescription"]}</td>\n'
            html +=  '</tr>\n'

        html += "</tbody></table></div>"
        return html
