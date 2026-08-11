
Add-Type -AssemblyName PresentationFramework

$Apps = @(
    [PSCustomObject]@{ Nome = "Google Chrome";        Id = "Google.Chrome" }
    [PSCustomObject]@{ Nome = "7-Zip";                 Id = "7zip.7zip" }
    [PSCustomObject]@{ Nome = "Adobe Acrobat Reader";  Id = "Adobe.Acrobat.Reader.64-bit" }
    [PSCustomObject]@{ Nome = "Anydesk";                Id = "AnyDeskSoftwareGmbH.AnyDesk" }
    [PSCustomObject]@{ Nome = "Microsoft Office (365)"; Id = "Microsoft.Office" }
    [PSCustomObject]@{ Nome = "Adobe Acrobat Reader";   Id = "Adobe.Acrobat.Reader" }
)

[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Instalador de Apps - Pos Formatacao" Height="560" Width="420"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="Selecione os apps para instalar:"
                   FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>

        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="AppList"/>
        </ScrollViewer>

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,10">
            <Button x:Name="BtnTodos" Content="Marcar Todos" Width="120" Margin="0,0,10,0"/>
            <Button x:Name="BtnNenhum" Content="Desmarcar Todos" Width="120"/>
        </StackPanel>

        <StackPanel Grid.Row="3">
            <ProgressBar x:Name="Progresso" Height="20" Margin="0,0,0,10"/>
            <TextBlock x:Name="StatusText" Text="Aguardando..." Margin="0,0,0,10"/>
            <Button x:Name="BtnInstalar" Content="INSTALAR SELECIONADOS" Height="40" FontWeight="Bold"/>
        </StackPanel>
    </Grid>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $Xaml
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$AppListPanel = $Window.FindName("AppList")
$BtnInstalar  = $Window.FindName("BtnInstalar")
$BtnTodos     = $Window.FindName("BtnTodos")
$BtnNenhum    = $Window.FindName("BtnNenhum")
$Progresso    = $Window.FindName("Progresso")
$StatusText   = $Window.FindName("StatusText")

# Cria um checkbox pra cada app
$CheckBoxes = @{}
foreach ($App in $Apps) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $App.Nome
    $cb.Margin = "0,5,0,5"
    $cb.FontSize = 13
    $cb.Tag = $App.Id
    $AppListPanel.Children.Add($cb) | Out-Null
    $CheckBoxes[$App.Id] = $cb
}

$BtnTodos.Add_Click({ $CheckBoxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnNenhum.Add_Click({ $CheckBoxes.Values | ForEach-Object { $_.IsChecked = $false } })

$BtnInstalar.Add_Click({
    $Selecionados = $CheckBoxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true }

    if ($Selecionados.Count -eq 0) {
        $StatusText.Text = "Nenhum app selecionado."
        return
    }

    $BtnInstalar.IsEnabled = $false
    $Progresso.Maximum = $Selecionados.Count
    $Progresso.Value = 0
    $i = 0

    foreach ($item in $Selecionados) {
        $i++
        $Id = $item.Key
        $Nome = $item.Value.Content
        $StatusText.Text = "Instalando ($i/$($Selecionados.Count)): $Nome"
        $Window.Dispatcher.Invoke([action]{}, "Render")

        # --silent + --accept-* evita prompts; -e garante o Id exato
        # --source winget garante buscar sempre a versao mais atual do winget
        Start-Process winget -ArgumentList "install --id $Id -e --silent --accept-source-agreements --accept-package-agreements --source winget" -Wait -NoNewWindow

        $Progresso.Value = $i
    }

    $StatusText.Text = "Concluido! $($Selecionados.Count) app(s) instalado(s)."
    $BtnInstalar.IsEnabled = $true
})

$Window.ShowDialog() | Out-Null
