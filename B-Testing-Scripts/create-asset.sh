#!/bin/bash

create_asset() {
    # Set Snipe-IT API URL and authentication token
    SNIPE_API_URL="https://mit.jairenz.xyz/api/v1/hardware"
    API_TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiN2VhOTRlYzZiNTA1OWM2YTQ1NzI5Y2QzZjRlNjdkZjE2NWZiMTgyZGQ1MjIzY2U1NmZjNmM0ZGFmMjhiMmVlNTk4YWFiNWNmMGE2YTUxMWMiLCJpYXQiOjE3Mzg1ODIyMjIuMTY1MzM5LCJuYmYiOjE3Mzg1ODIyMjIuMTY1MzQyLCJleHAiOjIzNjk3MzQyMjIuMTM1Njc5LCJzdWIiOiIxIiwic2NvcGVzIjpbXX0.EjNN5HeHidkNu9yfSYgG-XDPgEesyJ7-RSXvtBeuzR_GW4vtQtEM1mIPhZqhhr0MTicJ6XpaxOZ1oKY8a8a4zuzrc6kzxbZ8CRF8bgEfHRhvsJiZRuOwC93G8D1Q-mOdw2qGFNOjTSM250y45Epb6b_qyEVF9wWb3dOqSR9Y_zXr_eDw6JKUhaa8oLNNKPzkSk5pb4BK8OPS-3EQ-eWL-9oUL_DjaHoce04lPMslftJANmmb9ppt6osRR2zlKA5WKBSiYzVNJuh_SgXEhAPJiUEUvdh8rbhBcmYqbbjrsAX2HAT7xFkUNqAIYsLbTiY2jcO_a-dRET1M1nA0gLLj6fUdeKjZZuxCsumEL3fYj_LnMrRZy9p769hcXCI8azXFTsVUz0ZnHyZXPaS0N7pg9zuW_esOgQ9T8hvoaS2ZKjmfZbWEMHJITUEHgoc7frgndHr3wi0DWOSNCL-cIdJpJO9qo-6ZtnRN-W55_KneI3HsUKgyIzywN3EP25W04UQmCOaNk-4K4RP3PzKiD5NNwu06hdaDX61eaE1Bwpl4KxGAc7BlFOKysdLkD9Zmog7k4rptElL_ZWpFuvt2I4Kw6Eb3g-dVlH7F5qzNftHPCzSrDukENRpiYaRjlL7gHE3yk-6ExT3noy3AOcY3BL-K3y96ssNXBZTUi7oq4Mkeppk"

    # Preset values for the new asset
    ASSET_NAME="Test Laptop Asset - $(date +%Y%m%d%H%M%S)"
    MODEL_ID=16  # Replace with the actual model ID from Snipe-IT
    LOCATION_ID=1  # Replace with the actual location ID from Snipe-IT
    CATEGORY_ID=4  # Replace with the actual category ID from Snipe-IT

    # Generate the asset tag: "TEST-" + the last 8 digits of the current epoch time
    EPOCH_TIME=$(date +%s)  # Get the current epoch time (seconds since 1970-01-01)
    LAST_8_DIGITS=${EPOCH_TIME: -8}  # Extract the last 8 digits of the epoch time
    ASSET_TAG="TEST-$LAST_8_DIGITS"

    echo "Asset Tag is: $ASSET_TAG"
    echo "Asset Name is: $ASSET_NAME"

    # Create the JSON data string
    JSON_DATA=$(jq -n \
        --arg asset_tag "$ASSET_TAG" \
        --arg name "$ASSET_NAME" \
        --arg model_id "$MODEL_ID" \
        --arg location_id "$LOCATION_ID" \
        --arg category_id "$CATEGORY_ID" \
        '{
            asset_tag: $asset_tag,
            name: $name,
            model_id: ($model_id | tonumber),
            location_id: ($location_id | tonumber),
            category_id: ($category_id | tonumber),
            status_id: 2
        }')

    # Create a new asset via Snipe-IT API using POST method
    RESPONSE=$(curl -s --location $SNIPE_API_URL \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$API_TOKEN \
    --data "$JSON_DATA")

    # echo "Response: $RESPONSE"

    # Check if the asset was created successfully
    SUCCESS=$(echo $RESPONSE | jq -r '.status')

    if [ "$SUCCESS" == "success" ]; then
        echo "Asset added successfully with tag: $ASSET_TAG"
    else
        echo "Error: Failed to add asset. Response: $RESPONSE"
    fi
}

# Run the function every minute until the script is killed
while true; do
    create_asset
    sleep 60
done