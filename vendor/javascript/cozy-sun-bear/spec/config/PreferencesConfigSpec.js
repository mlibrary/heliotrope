describe('PreferencesConfig', function () {

	var PreferencesConfig = cozy.PreferencesConfig;
	var sanitizePreference = cozy.sanitizePreference;
	var sanitizePreferences = cozy.sanitizePreferences;

	describe('Valid Values Configuration', function () {

		it('should have valid font options', function () {
			expect(PreferencesConfig.fonts.valid).to.contain('default');
			expect(PreferencesConfig.fonts.default).to.eql('default');
		});

		it('should have text size values from 50 to 400 in 10% increments', function () {
			expect(PreferencesConfig.textSize.valid).to.contain(50);
			expect(PreferencesConfig.textSize.valid).to.contain(100);
			expect(PreferencesConfig.textSize.valid).to.contain(400);
			expect(PreferencesConfig.textSize.default).to.eql(100);
		});

		it('should have valid spacing options', function () {
			expect(PreferencesConfig.wordSpacing.valid).to.contain('auto');
			expect(PreferencesConfig.wordSpacing.valid).to.contain('.125rem');
			expect(PreferencesConfig.letterSpacing.default).to.eql('auto');
		});
	});

	describe('#sanitizePreference', function () {

		it('should return valid text size unchanged', function () {
			var result = sanitizePreference('textSize', 150);
			expect(result).to.eql(150);
		});

		it('should snap text size that is too high to the maximum valid step', function () {
			var result = sanitizePreference('textSize', 9999);
			expect(result).to.eql(400);
		});

		it('should snap text size that is too low to the minimum valid step', function () {
			var result = sanitizePreference('textSize', 10);
			expect(result).to.eql(50);
		});

		it('should snap text size to the nearest valid step', function () {
			var result = sanitizePreference('textSize', 156);
			expect(result).to.eql(160);
		});

		it('should return valid word spacing unchanged', function () {
			var result = sanitizePreference('wordSpacing', '.125rem');
			expect(result).to.eql('.125rem');
		});

		it('should return default for invalid word spacing', function () {
			var result = sanitizePreference('wordSpacing', 'invalid-value');
			expect(result).to.eql('auto');
		});

		it('should return valid font unchanged', function () {
			var result = sanitizePreference('fonts', 'Arial,Helvetica Neue,Helvetica,sans-serif');
			expect(result).to.eql('Arial,Helvetica Neue,Helvetica,sans-serif');
		});

		it('should reject font with script tags', function () {
			var result = sanitizePreference('fonts', '<script>alert("xss")</script>');
			expect(result).to.eql('default');
		});

		it('should reject font with javascript protocol', function () {
			var result = sanitizePreference('fonts', 'javascript:alert(1)');
			expect(result).to.eql('default');
		});

		it('should reject font with event handlers', function () {
			var result = sanitizePreference('fonts', 'onclick=alert(1)');
			expect(result).to.eql('default');
		});

		it('should convert string numbers to integers for textSize', function () {
			var result = sanitizePreference('textSize', '180');
			expect(result).to.eql(180);
		});

		it('should return default for NaN text size', function () {
			var result = sanitizePreference('textSize', 'not-a-number');
			expect(result).to.eql(100);
		});
	});

	describe('#sanitizePreferences', function () {

		it('should sanitize all valid preferences unchanged', function () {
			var input = {
				font: 'Arial,Helvetica Neue,Helvetica,sans-serif',
				text_size: 120,
				word_spacing: '.125rem',
				letter_spacing: '.0675rem',
				line_height: '1.5'
			};
			var result = sanitizePreferences(input);
			expect(result.font).to.eql('Arial,Helvetica Neue,Helvetica,sans-serif');
			expect(result.text_size).to.eql(120);
			expect(result.word_spacing).to.eql('.125rem');
		});

		it('should sanitize mixed valid and invalid preferences', function () {
			var input = {
				font: 'Verdana,Geneva,sans-serif',
				text_size: 150,
				word_spacing: 'invalid-value',
				letter_spacing: '.125rem',
				scale: 9999
			};
			var result = sanitizePreferences(input);
			expect(result.font).to.eql('Verdana,Geneva,sans-serif');
			expect(result.text_size).to.eql(150);
			expect(result.word_spacing).to.eql('auto');
			expect(result.letter_spacing).to.eql('.125rem');
			expect(result.scale).to.eql(400);
		});

		it('should handle empty input gracefully', function () {
			var result = sanitizePreferences({});
			expect(result).to.eql({});
		});

		it('should handle null input gracefully', function () {
			var result = sanitizePreferences(null);
			expect(result).to.eql({});
		});

		it('should handle undefined input gracefully', function () {
			var result = sanitizePreferences(undefined);
			expect(result).to.eql({});
		});

		it('should pass through unknown keys', function () {
			var input = {
				text_size: 120,
				custom_field: 'some value'
			};
			var result = sanitizePreferences(input);
			expect(result.text_size).to.eql(120);
			expect(result.custom_field).to.eql('some value');
		});
	});

	describe('Security Tests', function () {

		it('should reject XSS attempts in font field', function () {
			var maliciousInputs = [
				'<script>alert("XSS")</script>',
				'javascript:alert(1)',
				'onclick=alert(1)',
				'<img src=x onerror=alert(1)>'
			];

			maliciousInputs.forEach(function(input) {
				var result = sanitizePreference('fonts', input);
				expect(result).to.eql('default');
			});
		});

		it('should reject potential CSS injection in spacing fields', function () {
			var maliciousInputs = [
				'red}body{background',
				'0;display:none',
				'1rem;color:red'
			];

			maliciousInputs.forEach(function(input) {
				var result = sanitizePreference('wordSpacing', input);
				expect(result).to.eql('auto');
			});
		});
	});

	describe('Edge Cases', function () {

		it('should handle null values for textSize', function () {
			var result = sanitizePreference('textSize', null);
			expect(result).to.eql(100);
		});

		it('should handle undefined values for textSize', function () {
			var result = sanitizePreference('textSize', undefined);
			expect(result).to.eql(100);
		});

		it('should handle empty strings for wordSpacing', function () {
			var result = sanitizePreference('wordSpacing', '');
			expect(result).to.eql('auto');
		});
	});
});

