from agent.detection.url_analyzer import analyze_url


def test_ordinary_https_url_has_no_heuristic_flags():
    result = analyze_url("https://www.example.org/article")
    assert result["findings"] == []
    assert result["score"] == 0


def test_detects_visible_url_red_flags_without_visiting():
    result = analyze_url("http://192.0.2.10/login?next=https%3A%2F%2Fother.invalid")
    assert {item["rule_id"] for item in result["findings"]} >= {
        "url.cleartext_http",
        "url.ip_host",
        "url.sensitive_path",
        "url.redirect_parameter",
    }


def test_rejects_non_web_schemes():
    assert any(item["rule_id"] == "url.invalid" for item in analyze_url("javascript:alert(1)")["findings"])


def test_detects_lookalike_and_misleading_brand_subdomains():
    lookalike = analyze_url("https://paytmm.example.invalid")
    misleading = analyze_url("https://paytm.com.attacker.invalid")
    legitimate_india_domain = analyze_url("https://paytm.co.in")
    assert any(item["rule_id"] == "url.lookalike_brand" for item in lookalike["findings"])
    assert any(item["rule_id"] == "url.misleading_subdomain" for item in misleading["findings"])
    assert not any(
        item["rule_id"] == "url.misleading_subdomain"
        for item in legitimate_india_domain["findings"]
    )
