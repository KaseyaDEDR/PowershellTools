
Describe "Get-ICTaskStatistics" {
    
    It "Gets task statistics for default 7 day period" {
        $stats = Get-ICTaskStatistics
        $stats | Should -Not -Be $null
        $stats.TotalTasks | Should -BeOfType [int]
        $stats.ActiveTasks | Should -BeOfType [int]
        $stats.CompleteTasks | Should -BeOfType [int]
        $stats.ErrorTasks | Should -BeOfType [int]
        $stats.CancelledTasks | Should -BeOfType [int]
        $stats.OtherTasks | Should -BeOfType [int]
        $stats.TimeRangeStart | Should -Not -Be $null
        $stats.TimeRangeEnd | Should -Not -Be $null
    }
    
    It "Accepts Days parameter and returns statistics" {
        $stats = Get-ICTaskStatistics -Days 30
        $stats | Should -Not -Be $null
        $stats.TotalTasks | Should -BeGreaterOrEqual 0
    }
    
    It "Returns zero statistics when no tasks found" {
        # Using a very short time range to potentially get no results
        $stats = Get-ICTaskStatistics -Days 1
        $stats | Should -Not -Be $null
        $stats.TotalTasks | Should -BeGreaterOrEqual 0
    }
    
    It "Validates that sum of status counts equals total" {
        $stats = Get-ICTaskStatistics
        if ($stats.TotalTasks -gt 0) {
            $sum = $stats.ActiveTasks + $stats.CompleteTasks + $stats.ErrorTasks + $stats.CancelledTasks + $stats.OtherTasks
            $sum | Should -Be $stats.TotalTasks
        }
    }
}
