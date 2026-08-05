#!/usr/bin/env python3
"""Fail the stock refresh before commit if its XML files disagree."""

from datetime import date
from decimal import Decimal, InvalidOperation
from email.utils import parsedate_to_datetime
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent.parent
GOOGLE = "{http://base.google.com/ns/1.0}"
SITE = "https://www.windsor-express.co.uk"
STORE_CODE = "11126744882028006931"


def fail(message):
    raise SystemExit(f"Generated-file validation failed: {message}")


def parse_xml(name):
    try:
        return ET.parse(ROOT / name).getroot()
    except (OSError, ET.ParseError) as error:
        fail(f"{name} is not valid XML ({error})")


def child_text(element, name, required=True):
    child = element.find(name)
    value = (child.text or "").strip() if child is not None else ""
    if required and not value:
        fail(f"an item is missing {name.replace(GOOGLE, 'g:')}")
    return value


def item_map(root, filename):
    items = {}
    for item in root.findall("./channel/item"):
        item_id = child_text(item, GOOGLE + "id")
        if item_id in items:
            fail(f"{filename} contains duplicate product id {item_id}")
        items[item_id] = item
    return items


def money(value, field, item_id):
    number, separator, currency = value.partition(" ")
    if separator != " " or currency != "GBP":
        fail(f"{field} for {item_id} must use GBP")
    try:
        amount = Decimal(number)
    except InvalidOperation:
        fail(f"{field} for {item_id} is not numeric")
    if not amount.is_finite() or amount <= 0:
        fail(f"{field} for {item_id} must be a positive number")
    return amount


def validate_build_date(root, filename):
    value = root.findtext("./channel/lastBuildDate", "").strip()
    try:
        parsedate_to_datetime(value)
    except (TypeError, ValueError):
        fail(f"{filename} has an invalid lastBuildDate")


merchant_root = parse_xml("merchant-feed.xml")
local_root = parse_xml("local-inventory.xml")
sitemap_root = parse_xml("sitemap.xml")

validate_build_date(merchant_root, "merchant-feed.xml")
validate_build_date(local_root, "local-inventory.xml")

merchant = item_map(merchant_root, "merchant-feed.xml")
local = item_map(local_root, "local-inventory.xml")
if set(merchant) != set(local):
    fail("merchant and local inventory product ids do not match")

merchant_links = set()
for item_id, item in merchant.items():
    if child_text(item, GOOGLE + "availability") != "in_stock":
        fail(f"merchant availability for {item_id} is not in_stock")
    link = child_text(item, GOOGLE + "link")
    if not link.startswith(SITE + "/phones/"):
        fail(f"merchant link for {item_id} is outside the Windsor Express site")
    if link in merchant_links:
        fail(f"multiple Merchant items use the same product link {link}")
    merchant_links.add(link)
    regular = money(child_text(item, GOOGLE + "price"), "price", item_id)
    sale_value = child_text(item, GOOGLE + "sale_price", required=False)
    effective = money(sale_value, "sale_price", item_id) if sale_value else regular

    local_item = local[item_id]
    if child_text(local_item, GOOGLE + "store_code") != STORE_CODE:
        fail(f"local inventory store code changed for {item_id}")
    if child_text(local_item, GOOGLE + "availability") != "in_stock":
        fail(f"local availability for {item_id} is not in_stock")
    try:
        quantity = int(child_text(local_item, GOOGLE + "quantity"))
    except ValueError:
        fail(f"local quantity for {item_id} is not an integer")
    if quantity <= 0:
        fail(f"local quantity for {item_id} must be positive")
    local_price = money(child_text(local_item, GOOGLE + "price"), "local price", item_id)
    if local_price != effective:
        fail(f"merchant and local prices disagree for {item_id}")

sitemap_namespace = "{http://www.sitemaps.org/schemas/sitemap/0.9}"
sitemap_locations = []
for url in sitemap_root.findall(sitemap_namespace + "url"):
    location = (url.findtext(sitemap_namespace + "loc") or "").strip()
    if not location:
        fail("sitemap.xml contains a URL without a location")
    sitemap_locations.append(location)
    lastmod = (url.findtext(sitemap_namespace + "lastmod") or "").strip()
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", lastmod):
        fail(f"sitemap.xml has an invalid lastmod for {location}")
    try:
        date.fromisoformat(lastmod)
    except ValueError:
        fail(f"sitemap.xml has an invalid lastmod for {location}")

if len(sitemap_locations) != len(set(sitemap_locations)):
    fail("sitemap.xml contains duplicate locations")

required_locations = {
    SITE + "/phones-for-sale-windsor.html",
    SITE + "/phones/",
    *merchant_links,
}
missing = required_locations - set(sitemap_locations)
if missing:
    fail("sitemap.xml is missing " + ", ".join(sorted(missing)))

print(
    f"Validated {len(merchant)} Merchant item(s), {len(local)} local item(s), "
    f"and {len(sitemap_locations)} sitemap URL(s)."
)
