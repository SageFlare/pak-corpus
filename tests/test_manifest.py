from pakcorpus_validate.manifest import validate_manifest, STATES, VECTORS


def _m(**kw):
    base = {
        "name": "s",
        "vector": "benign",
        "intent": "none",
        "expected_state": "benign",
        "notes": "",
    }
    base.update(kw)
    return base


def test_valid_entry_when_pak_exists(tmp_path):
    (tmp_path / "s.pak").write_bytes(b"x")
    assert validate_manifest([_m()], str(tmp_path)) == []


def test_missing_pak_is_error(tmp_path):
    errs = validate_manifest([_m()], str(tmp_path))
    assert any("s.pak" in e for e in errs)


def test_bad_state_is_error(tmp_path):
    (tmp_path / "s.pak").write_bytes(b"x")
    errs = validate_manifest([_m(expected_state="exploded")], str(tmp_path))
    assert errs


def test_bad_vector_is_error(tmp_path):
    (tmp_path / "s.pak").write_bytes(b"x")
    errs = validate_manifest([_m(vector="wormhole")], str(tmp_path))
    assert errs


def test_absolute_path_in_field_is_error(tmp_path):
    (tmp_path / "s.pak").write_bytes(b"x")
    errs = validate_manifest([_m(notes="see C:\\Users\\bob\\x")], str(tmp_path))
    assert errs


def test_states_and_vectors_known_sets():
    assert STATES == {"benign", "attempted", "malicious"}
    assert {"asset_replacement", "launch_url", "benign"} <= VECTORS
