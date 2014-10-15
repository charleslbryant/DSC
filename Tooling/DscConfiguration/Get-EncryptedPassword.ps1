function Get-DscEncryptedPassword
{
    [cmdletbinding(DefaultParameterSetName='ByStoreName')]
    param (
        [parameter(
            ParameterSetName = 'ByStoreName',
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [Alias('BaseName')]
        [string]
        $StoreName,
        [parameter(
            ParameterSetName = 'ByStoreName'
        )]
        [string]
        $Path = (Join-path $script:ConfigurationDataPath 'Credentials'),
        [parameter(
            ParameterSetName = 'ByPipeline',
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [Alias('FullName')]
        [string]
        $EncryptedFilePath,
        [parameter()]
        [string[]]
        $UserName
    )
    process
    {
        if (Test-LocalCertificate)
        {
            $DecryptedDataFile = $null

            try
            {
                if (-not $PSBoundParameters.ContainsKey('EncryptedFilePath'))
                {
                    $EncryptedFilePath = Join-Path $Path "$StoreName.psd1.encrypted"
                }

                Write-Verbose "Decrypting $EncryptedFilePath."
                $DecryptedDataFile = ConvertFrom-EncryptedFile -path $EncryptedFilePath -CertificatePath $LocalCertificatePath -ErrorAction Stop

                Write-Verbose "Loading $($DecryptedDataFile.BaseName) into Credentials."
                $Credentials = Get-Hashtable $DecryptedDataFile.FullName -ErrorAction Stop

                if ($PSBoundParameters.ContainsKey('UserName'))
                {
                    $CredentialsToReturn = @{}
                    foreach ($User in $UserName)
                    {
                        $CredentialsToReturn.Add($User,$Credentials[$User])
                    }
                    return $CredentialsToReturn
                }
                else
                {
                    return $Credentials
                }
            }
            catch
            {
                throw
            }
            finally
            {
                if ($null -ne $DecryptedDataFile)
                {
                    Remove-PlainTextPassword $DecryptedDataFile.FullName
                }
            }
        }
    }
}
