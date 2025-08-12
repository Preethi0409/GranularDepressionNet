function features = extract_features(image)
    image = im2double(image); % Convert to double (safe for entropy function)
    features = [mean2(image), var(double(image(:))), entropy(image)];
end
